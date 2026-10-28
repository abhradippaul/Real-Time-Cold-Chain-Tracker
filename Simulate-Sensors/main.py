#!/usr/bin/env python3
"""
Cold chain sensor simulator.

Generates JSON temperature readings for a fleet of refrigerated trucks and
uploads each one to S3 as its own object, which triggers the validator Lambda.

Usage examples:
  python simulate_sensors.py --bucket coldchain-raw-readings
  python simulate_sensors.py --bucket coldchain-raw-readings --trucks 5 --rounds 20 --interval 2
  python simulate_sensors.py --bucket coldchain-raw-readings --bad-rate 0.1 --alert-rate 0.15
  python simulate_sensors.py --bucket coldchain-raw-readings --dry-run

Requires: pip install boto3   (and AWS credentials via `aws configure` or env vars)
"""
import argparse
import json
import random
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path


def make_reading(truck_id: str, last_temp: float, alert_rate: float) -> dict:
    """Random-walk around a safe 2-4 C band, with occasional excursions above 5 C."""
    if random.random() < alert_rate:
        temp = random.uniform(5.2, 9.0)  # breach, should trigger an SNS email
    else:
        temp = last_temp + random.uniform(-0.4, 0.4)
        temp = min(max(temp, 1.0), 4.8)  # keep normal readings in safe range
    return {
        "truck_id": truck_id,
        "temperature": round(temp, 2),
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }


def corrupt(reading: dict) -> tuple[str, str]:
    """Return (body, kind) for a deliberately invalid payload to test validation."""
    kind = random.choice(["not_json", "missing_field", "out_of_range", "bad_type"])
    if kind == "not_json":
        return "{this is not valid json", kind
    bad = dict(reading)
    if kind == "missing_field":
        bad.pop("temperature")
    elif kind == "out_of_range":
        bad["temperature"] = 999
    elif kind == "bad_type":
        bad["temperature"] = "hot"
    return json.dumps(bad), kind


def main():
    p = argparse.ArgumentParser(description="Simulate cold chain sensor uploads to S3")
    p.add_argument("--bucket", required=True, help="Target S3 bucket")
    p.add_argument("--prefix", default="incoming/", help="Key prefix (default: incoming/)")
    p.add_argument("--trucks", type=int, default=3, help="Number of trucks (default: 3)")
    p.add_argument("--rounds", type=int, default=10, help="Readings per truck (default: 10)")
    p.add_argument("--interval", type=float, default=1.0, help="Seconds between rounds (default: 1)")
    p.add_argument("--alert-rate", type=float, default=0.1, help="Chance a reading exceeds 5 C (default: 0.1)")
    p.add_argument("--bad-rate", type=float, default=0.05, help="Chance a payload is malformed (default: 0.05)")
    p.add_argument("--region", default=None, help="AWS region (optional)")
    p.add_argument("--dry-run", action="store_true", help="Write files locally to ./sample_logs instead of uploading")
    p.add_argument("--seed", type=int, default=None, help="Random seed for repeatable runs")
    args = p.parse_args()

    if args.seed is not None:
        random.seed(args.seed)

    s3 = None
    if args.dry_run:
        out_dir = Path("sample_logs")
        out_dir.mkdir(exist_ok=True)
    else:
        import boto3
        s3 = boto3.client("s3", region_name=args.region)

    trucks = [f"T-{101 + i}" for i in range(args.trucks)]
    last = {t: random.uniform(2.0, 4.0) for t in trucks}
    sent = alerts = bad = 0

    print(f"Simulating {args.trucks} trucks x {args.rounds} rounds "
          f"({'dry run' if args.dry_run else 's3://' + args.bucket + '/' + args.prefix})")

    for r in range(1, args.rounds + 1):
        for t in trucks:
            reading = make_reading(t, last[t], args.alert_rate)
            last[t] = min(reading["temperature"], 4.8)  # don't let a spike drag the baseline up

            if random.random() < args.bad_rate:
                body, kind = corrupt(reading)
                bad += 1
                tag = f"BAD({kind})"
            else:
                body = json.dumps(reading)
                tag = "ALERT" if reading["temperature"] > 5 else "ok"
                alerts += tag == "ALERT"

            key = f"{args.prefix}{t}/{datetime.now(timezone.utc):%Y%m%dT%H%M%S}-{uuid.uuid4().hex[:8]}.json"

            if args.dry_run:
                path = out_dir / key.replace("/", "_")
                path.write_text(body)
            else:
                s3.put_object(Bucket=args.bucket, Key=key, Body=body.encode(),
                              ContentType="application/json")
            sent += 1
            print(f"[round {r:>3}] {t} {tag:<22} -> {key}")

        if r < args.rounds:
            time.sleep(args.interval)

    print(f"\nDone. Uploaded {sent} files | alerts (>5C): {alerts} | malformed: {bad}")


if __name__ == "__main__":
    main()