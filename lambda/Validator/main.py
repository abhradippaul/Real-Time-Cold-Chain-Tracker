import json, boto3, os
s3, sqs = boto3.client("s3"), boto3.client("sqs")

def handler(event, context):
    print(event)
    for rec in event["Records"]:
        obj = s3.get_object(Bucket=rec["s3"]["bucket"]["name"],
                            Key=rec["s3"]["object"]["key"])
        try:
            d = json.loads(obj["Body"].read())
            assert isinstance(d["truck_id"], str)
            assert -50 <= float(d["temperature"]) <= 60
            assert d["timestamp"]
        except Exception as e:
            print(f"Rejected {rec['s3']['object']['key']}: {e}")
            continue
        sqs.send_message(QueueUrl=os.environ["QUEUE_URL"], MessageBody=json.dumps(d))
        print(f"Accepted {rec['s3']['object']['key']}")