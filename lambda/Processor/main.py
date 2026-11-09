import json, boto3, os
from decimal import Decimal
# import psycopg

ddb = boto3.resource("dynamodb").Table(os.environ["DYNAMODB_TABLE_NAME"])
sns = boto3.client("sns")
# secret = json.loads(boto3.client("secretsmanager")
#           .get_secret_value(SecretId=os.environ["SECRET_ID"])["SecretString"])
# conn = None

# def db():
#     global conn
#     if conn is None or not conn.open:
#         conn = psycopg.connect(host=secret["host"], user=secret["username"],
#                                password=secret["password"], database="temperature",
#                                autocommit=True)
#     return conn

def handler(event, context):
    print("Processor Lambda Triggered")
    print(event)
    for rec in event["Records"]:
        d = json.loads(rec["body"])
        temp, truck, ts = float(d["temperature"]), d["truck_id"], d["timestamp"]

        # Hot store: only overwrite if this reading is newer
        try:
            ddb.put_item(
                Item={"truck_id": truck, "temperature": Decimal(str(temp)), "timestamp": ts},
                ConditionExpression="attribute_not_exists(truck_id) OR #t < :ts",
                ExpressionAttributeNames={"#t": "timestamp"},
                ExpressionAttributeValues={":ts": ts})
        except ddb.meta.client.exceptions.ConditionalCheckFailedException:
            pass

        # Cold store: idempotent insert
        # with db().cursor() as c:
        #     c.execute("INSERT IGNORE INTO readings VALUES (%s, %s, %s)",
        #               (truck, ts.replace("T", " ").rstrip("Z"), temp))

        if temp > 5:
            sns.publish(TopicArn=os.environ["TOPIC_ARN"],
                        Subject=f"Temp alert: {truck}",
                        Message=f"{truck} reported {temp}°C at {ts} (limit 5°C)")