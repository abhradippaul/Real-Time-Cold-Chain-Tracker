import json
import os
from decimal import Decimal
import boto3
import psycopg

ddb = boto3.resource("dynamodb").Table(os.environ["DYNAMODB_TABLE_NAME"])
sns = boto3.client("sns")

secret = None
conn = None


def get_secret():
    """Retrieve database connection parameters from AWS Secrets Manager."""
    global secret
    if secret is None:
        secret_id = os.environ.get("SECRET_ID")
        if not secret_id:
            raise ValueError("SECRET_ID environment variable is not set")
        sm = boto3.client("secretsmanager")
        res = sm.get_secret_value(SecretId=secret_id)
        secret = json.loads(res["SecretString"])
    return secret


def db():
    """Return an active PostgreSQL connection using credentials from Secrets Manager."""
    global conn
    if conn is None or conn.closed:
        sec = get_secret()
        # AWS RDS master_user_secret provides 'username' and 'password'.
        # 'host' and 'port' come from environment variables.
        host = os.environ.get("DB_HOST", sec.get("host"))
        if not host:
            raise ValueError("DB_HOST environment variable is not set")
        port = int(os.environ.get("DB_PORT", sec.get("port", 5432)))
        user = sec.get("username", "postgres")
        password = sec["password"]
        dbname = os.environ.get("DB_NAME", sec.get("dbname", "temperature"))

        conn = psycopg.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            dbname=dbname,
            autocommit=True,
            connect_timeout=5,
            sslmode="prefer",
        )
    return conn


def handler(event, context):
    print("Processor Lambda Triggered")
    print(event)

    for rec in event.get("Records", []):
        d = json.loads(rec["body"])
        temp, truck, ts = float(d["temperature"]), d["truck_id"], d["timestamp"]

        # Hot store: only overwrite if this reading is newer
        try:
            ddb.put_item(
                Item={
                    "truck_id": truck,
                    "temperature": Decimal(str(temp)),
                    "timestamp": ts,
                },
                ConditionExpression="attribute_not_exists(truck_id) OR #t < :ts",
                ExpressionAttributeNames={"#t": "timestamp"},
                ExpressionAttributeValues={":ts": ts},
            )
        except ddb.meta.client.exceptions.ConditionalCheckFailedException:
            pass

        # Cold store: idempotent historical audit insert into PostgreSQL
        try:
            with db().cursor() as c:
                c.execute(
                    """
                    INSERT INTO temperature_history (truck_id, temperature, recorded_at)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (truck_id, recorded_at) DO NOTHING
                    """,
                    (truck, temp, ts.replace("T", " ").rstrip("Z")),
                )
        except Exception as e:
            print(f"Error persisting to cold store for truck {truck}: {e}")

        # Real-time alert on critical temperature threshold breach
        if temp > 5:
            sns.publish(
                TopicArn=os.environ["TOPIC_ARN"],
                Subject=f"Temp alert: {truck}",
                Message=f"{truck} reported {temp}°C at {ts} (limit 5°C)",
            )
