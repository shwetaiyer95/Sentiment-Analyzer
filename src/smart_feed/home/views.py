import os
import json

from django.contrib.auth.decorators import login_required
from django.shortcuts import render, redirect
import requests

from django.contrib import messages
from home.models import Subscription, Tweets
from django.db.utils import IntegrityError


# @login_required
def subscribe_topics(request):
    topics = []
    default_options = ['Soccer', 'Anime', 'NFL', 'Tennis', 'Movies', 'Elections', 'Weather', 'Hollywood', 'Food',
                       'Covid']
    if request.method == 'POST':
        entered_topics = request.POST.getlist('topics')
        selected_topics_checkbox = request.POST.getlist('checks[]')
        user_id = request.user.id
        topics = entered_topics + selected_topics_checkbox
        for value in topics:
            value = value.strip()
            if value != "":
                Subscription.objects.get_or_create(userid=user_id, category=value)
                if value not in default_options:
                    # Refresh feed for custom topics
                    url = os.getenv("API_URL")
                    headers = {'auth': os.getenv("AUTH_TOKEN")}
                    body = {"topic": value, "userid": str(request.user.id), "api_key": os.getenv("API_KEY")}
                    requests.post(url, json=body, headers=headers)
        return redirect('sentiments')
    return render(request, 'subscribe_topics.html', {"topics": topics})


# @login_required
def get_sentiment(request):
    first_15_subs = Subscription.objects.filter(userid=request.user.id).order_by('-id').all()[:15]
    topics = [item.category for item in first_15_subs]
    filtered_response = []

    if request.method == 'POST':
        if "topic" not in request.POST or "vibe" not in request.POST:
            messages.error(request, "Please select a Subscribed topic and the sentiment of tweets!")
            return redirect('sentiments')
        topic = request.POST["topic"]
        vibe = request.POST["vibe"]

        if vibe == "ALL":
            tweets = Tweets.objects.all().filter(category=topic).values()
        else:
            tweets = Tweets.objects.all().filter(category=topic, mood=vibe).values()
        filtered_response = tweets

    return render(request, 'get_sentiment.html', {"topics": topics, "results": filtered_response})
