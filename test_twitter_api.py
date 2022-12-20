import tweepy
import os
client = tweepy.Client(bearer_token=os.environ['barrier_token'])

# Replace with your own search query
query = 'football lang:hi'

tweets = client.search_recent_tweets(query=query, tweet_fields=['context_annotations', 'created_at'],max_results=10)

for tweet in tweets.data:
    print(tweet)
    break