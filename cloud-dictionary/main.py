import json
import boto3

# Create a DynamoDB client
dynamodb = boto3.client('dynamodb')

# Your DynamoDB table name
table_name = 'CloudDictionary'

def lambda_handler(event, context):
    # Get the term from the query string parameters
    term = event['queryStringParameters']['term']

    # Query the DynamoDB table for the term
    response = dynamodb.get_item(
        TableName=table_name,
        Key={
            'term': {
                'S': term
            }
        }
    )

    # Check if the term exists in the table
    if 'Item' in response:
        definition = response['Item']['definition']['S']
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',  # Allow all origins or specify a specific origin
                'Access-Control-Allow-Methods': 'OPTIONS,GET',  # Allowed methods
                'Access-Control-Allow-Headers': 'Content-Type',  # Allow necessary headers
            },
            'body': json.dumps({
                'term': term,
                'definition': definition
            })
        }
    else:
        return {
            'statusCode': 404,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',  # Allow all origins or specify a specific origin
                'Access-Control-Allow-Methods': 'OPTIONS,GET',  # Allowed methods
                'Access-Control-Allow-Headers': 'Content-Type',  # Allow necessary headers
            },
            'body': json.dumps({
                'message': 'Term not found'
            })
        }