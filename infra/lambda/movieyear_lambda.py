import boto3
import json

# initialize dynamodb boto3 object
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('movies_tf')

def lambda_handler(event, context):

    year = event["queryStringParameters"]["year"]
    
    if not year:
        return {
            'statusCode': 400,
            'body': json.dumps('Year is required')
        }
    
    response = table.query(
        IndexName = 'ReleaseYearIndex',
        KeyConditionExpression = 'releaseYear = :year',
        ExpressionAttributeValues = {
            ':year': year
        }
    )

    return {
        'statusCode': 200,
        'body': json.dumps(response['Items']),
        'headers': {
            'Content-Type': 'application/json'
        }
    }