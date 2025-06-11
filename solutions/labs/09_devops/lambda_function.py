from aws_lambda_powertools.metrics import Metrics
from aws_lambda_powertools.utilities.typing import LambdaContext
import json

metrics = Metrics(namespace="Custom/Lambda", service="StarWarsTracker")

def lambda_handler(event, context: LambdaContext):
    text = event.get("text", "")
    count = text.lower().count("star wars")
    
    metrics.add_metric(name="StarWarsMentions", unit="Count", value=count)
    metrics.flush_metrics()

    return {
        "statusCode": 200,
        "body": json.dumps({"mentions": count})
    }