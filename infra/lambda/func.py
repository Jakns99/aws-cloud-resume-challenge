import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('cloud-resume-challenge-counter')

def lambda_handler(event, context):
    response = table.get_item(Key={
        'ID': '0'
    })
    views = response['Item']['views']
    views = int(views) + 1
    print(views)
    response = table.put_item(Item={
        'ID': '0',
        'views': views
    })
    
    return {
    'statusCode': 200,
    'body': json.dumps({
        'views': int(views)
    }),
    'headers': {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
    }
}
