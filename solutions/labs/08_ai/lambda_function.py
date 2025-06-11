import boto3
import os

textract = boto3.client('textract')
translate = boto3.client('translate')
comprehend = boto3.client('comprehend')
s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key    = event['Records'][0]['s3']['object']['key']

    print(f"Processing file: s3://{bucket}/{key}")

    # Step 1: Call Textract
    response = textract.detect_document_text(
        Document={'S3Object': {'Bucket': bucket, 'Name': key}}
    )

    text = ' '.join([block['Text'] for block in response['Blocks'] if block['BlockType'] == 'LINE'])
    print(f"\nExtracted Text:\n{text}")

    # Step 2: Translate (German to English)
    translation = translate.translate_text(
        Text=text,
        SourceLanguageCode="de",
        TargetLanguageCode="en"
    )
    translated_text = translation['TranslatedText']
    print(f"\nTranslated Text:\n{translated_text}")

    # Step 3: Comprehend
    sentiment = comprehend.detect_sentiment(
        Text=translated_text,
        LanguageCode='en'
    )
    print(f"\nSentiment:\n{sentiment['Sentiment']} with score {sentiment['SentimentScore']}")
