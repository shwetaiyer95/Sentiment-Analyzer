from django.db import models


class Subscription(models.Model):
    class Meta:
        unique_together = (('userid', 'category'),)

    userid = models.IntegerField()
    category = models.CharField(max_length=20)


class Tweets(models.Model):
    class Meta:
        unique_together = (('category', 'tweet', 'user', 'hashtags', 'mood'),)

    category = models.CharField(max_length=20)
    tweet = models.CharField(max_length=300)
    user = models.CharField(max_length=20)
    hashtags = models.CharField(max_length=100)
    mood = models.CharField(max_length=20)
