import requests
from datetime import datetime
import time
import snscrape.modules.twitter as sntwitter
from bs4 import BeautifulSoup

webhook_url = "https://discord.com/api/webhooks/1360074049501532336/cnvwR6mP3ABihM2myF8Vg4FgvSTyRTAE7vZYlB0VyYmDOfC3pmLBIDqbvgGsrYCWa9Hy"

last_tweet_id = None
last_truth_post = None

def send_discord_alert(content, link, media_url=None):
    data = {
        "content": "@member 🔥 **New Trump Post Alert!** 🔥",
        "embeds": [
            {
                "title": "🚨 Trump just posted!",
                "description": f"{content}\n\n[View Original Post]({link})",
                "color": 16711680,
                "footer": {"text": "Trump Post Watchdog"},
                "timestamp": datetime.utcnow().isoformat()
            }
        ]
    }

    if media_url:
        data["embeds"][0]["image"] = {"url": media_url}

    response = requests.post(webhook_url, json=data)
    if response.status_code != 204:
        print(f"❌ Failed to send Discord message: {response.text}")

def get_latest_tweet():
    global last_tweet_id
    try:
        for tweet in sntwitter.TwitterUserScraper("realDonaldTrump").get_items():
            if last_tweet_id != tweet.id:
                last_tweet_id = tweet.id
                media = tweet.media[0].fullUrl if tweet.media else None
                return {
                    "text": tweet.content,
                    "link": f"https://twitter.com/i/web/status/{tweet.id}",
                    "media": media
                }
            break
    except Exception as e:
        print(f"[ERROR] Twitter scrape failed: {e}")
    return None

def get_latest_truth_post():
    global last_truth_post
    try:
        response = requests.get("https://truthsocialfeed.com/@realDonaldTrump", headers={"User-Agent": "Mozilla/5.0"})
        soup = BeautifulSoup(response.text, "html.parser")
        post = soup.find("div", class_="card-body")
        if post:
            text = post.get_text(strip=True)
            if text != last_truth_post:
                last_truth_post = text
                return {
                    "text": text,
                    "link": "https://truthsocial.com/@realDonaldTrump",
                    "media": None
                }
    except Exception as e:
        print(f"[ERROR] Truth Social scrape failed: {e}")
    return None

print("🚨 Trump Post Watchdog is running! (Ctrl+C to stop)")

while True:
    tweet = get_latest_tweet()
    if tweet:
        send_discord_alert(tweet["text"], tweet["link"], tweet["media"])

    truth = get_latest_truth_post()
    if truth:
        send_discord_alert(truth["text"], truth["link"])

    time.sleep(300)
