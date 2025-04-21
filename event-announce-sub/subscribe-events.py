import json
import boto3

def lambda_handler(event, context):
    # Log the entire event to CloudWatch
    print("Event received:", json.dumps(event))

    if 'body' in event:
        body = event['body']
        email = body.get('email', None)

        if email:
            sns_client = boto3.client('sns')

            try:
                # Subscribe the user to the SNS topic (email subscription)
                response = sns_client.subscribe(
                    TopicArn='arn:aws:sns:us-east-2:783764616094:EventAnnouncements',  # Replace with your SNS Topic ARN
                    Protocol='email',
                    Endpoint=email
                )

                return {
                    'statusCode': 200,
                    'body': json.dumps({'message': 'Subscription successful! Please check your email to confirm.'})
                }

            except Exception as e:
                print(f"Error subscribing user: {str(e)}")
                return {
                    'statusCode': 500,
                    'body': json.dumps({'error': f'Failed to subscribe: {str(e)}'}).encode('utf-8')
                }

        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Email not provided.'})
            }

    return {
        'statusCode': 400,
        'body': json.dumps({'error': 'Invalid request format.'})
    }