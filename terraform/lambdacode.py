import boto3
import os
import pymysql
import tweepy
import re
import json
import datetime

ENDPOINT = os.getenv("DB_ENDPOINT")
PORT = os.getenv("DB_PORT")
USER = os.getenv("DB_USER")
REGION = "us-east-1"
DBNAME = os.getenv("DB_NAME")
PASSWORD = os.getenv("DB_PASS")
os.environ['LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN'] = '1'
barrier_token = os.getenv("TWITTER_TOKEN")
default_topics = ['Soccer', 'Anime', 'NFL', 'Tennis', 'Movies', 'Elections', 'Weather', 'Hollywood', 'Food', 'Covid']


def lambda_handler(event, context):
    status_code = 500
    if 'refresh' in event and event['api_key'] == os.getenv("LAMBDA_KEY"):
        connection = pymysql.connect(host=ENDPOINT, user=USER, password=PASSWORD, database=DBNAME)
        print("Scheduled refresh at ", datetime.datetime.now())
        with connection.cursor() as cur:
            for topic in default_topics:
                try:
                    inject_data(topic, cur)
                except Exception as error:
                    print(error)
                connection.commit()
                print("Refreshed Topic:", topic)
        connection.close()
    else:
        body = json.loads(event['Records'][0]['body'])
        if 'userid' in body and 'topic' in body and body['api_key'] == os.getenv("LAMBDA_KEY"):
            connection = pymysql.connect(host=ENDPOINT, user=USER, password=PASSWORD, database=DBNAME)
            user_id, topic = body['userid'], body['topic']
            print("Refreshed Topic: ", topic, "for UserID:", user_id)
            if user_id and topic:
                with connection.cursor() as cur:
                    try:
                        inject_data(topic, cur)
                    except Exception as error:
                        print(error)
                    connection.commit()
            else:
                status_code = 500
            connection.close()
        else:
            status_code = 500
    return {
        'statusCode': status_code,
        'body': json.dumps('Request Processed')
    }


def inject_data(field, cur):
    client_twitter = tweepy.Client(bearer_token=barrier_token)
    query = field + ' lang:en -is:retweet'
    response = client_twitter.search_recent_tweets(query=query, tweet_fields=['context_annotations', 'created_at'],
                                                   expansions=['author_id'],
                                                   max_results=50)
    users = {u['id']: u for u in response.includes['users']}

    for i, tweet_obj in enumerate(response.data):
        tweet = tweet_obj.data['text']
        if users[tweet_obj.author_id]:
            user = users[tweet_obj.author_id]
            username = user.username
        else:
            username = ''
        session = boto3.Session(aws_session_token=os.getenv("TOKEN"), aws_access_key_id=os.getenv("ACCESS_KEY"),
                                aws_secret_access_key=os.getenv("SECRET_KEY"))
        client = session.client('comprehend')
        sentiment = client.detect_sentiment(Text=tweet, LanguageCode='en')['Sentiment']
        hashtag_list = re.findall(r"#\w+", tweet)
        hashtags = " ".join(hashtag_list)
        sql = """INSERT IGNORE INTO `home_tweets` (category,tweet,user,hashtags,mood) VALUES (%s,%s,%s,%s,%s)"""
        cur.execute(sql, (field, tweet, username, hashtags, sentiment))
