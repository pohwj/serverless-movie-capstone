import boto3
import json

# initialize dynamodb boto3 object
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('movies_tf')

def lambda_handler(event, context):

    response = table.scan()
    
    return {
        'statusCode': 200,
        'body': response['Items'],
        'headers': {
            'Content-Type': 'application/json'
        }
    }