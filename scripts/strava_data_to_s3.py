import os
import sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import re
import json
import time
import boto3
import requests
import configparser
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from helper.s3_data_migration import load_data_to_s3

config = configparser.ConfigParser()
config.read(os.path.expanduser('~/etc/strava/config.conf'))

BUCKET_NAME = config['S3']['BUCKET_NAME']
STRAVA_USERNAME = config['CREDENTIALS']['STRAVA_USERNAME']
STRAVA_PASSWORD = config['CREDENTIALS']['STRAVA_PASSWORD']
ATHLETE_ID = int(config['CREDENTIALS']['ATHLETE_ID'])
CLIENT_ID = int(config['CREDENTIALS']['CLIENT_ID'])
CLIENT_SECRET = config['CREDENTIALS']['CLIENT_SECRET']
REDIRECT_URI = config['CREDENTIALS']['REDIRECT_URI']
SCOPE = config['CREDENTIALS']['SCOPE']

s3 = boto3.client('s3')

def request_access_token():

    driver = webdriver.Chrome() 

    auth_url = (
        f"https://www.strava.com/oauth/authorize"
        f"?client_id={CLIENT_ID}"
        f"&response_type=code"
        f"&redirect_uri={REDIRECT_URI}"
        f"&scope={SCOPE}"
        f"&approval_prompt=auto"
    )
    driver.get(auth_url)

    time.sleep(15)
    username_input = driver.find_element(By.NAME, 'email')
    password_input = driver.find_element(By.NAME, 'password')

    username_input.send_keys(STRAVA_USERNAME)
    password_input.send_keys(STRAVA_PASSWORD)
    password_input.send_keys(Keys.RETURN)

    time.sleep(3)

    authorize_button = driver.find_element(By.XPATH, '//button[contains(text(), "Authorize")]')
    authorize_button.click()

    url = driver.current_url

    match = re.search(r'code=([^&]+)', url)
    if match:
        CODE = match.group(1)
        print(f"Access Code: {CODE}")

    driver.quit()

    response = requests.post(
        'https://www.strava.com/oauth/token',
        data={
            'client_id': CLIENT_ID,
            'client_secret': CLIENT_SECRET,
            'code': CODE,
            'grant_type': 'authorization_code'
        }
    )

    if response.status_code == 200:
        access_token = response.json()['access_token']
        print(f"Access Token: {access_token}")
    else:
        print(f"Error: {response.json()}")

    return access_token

def request_data(access_token):

    headers = {
    'Authorization': f'Bearer {access_token}'
    }  

    request_count = 0

    def sleep_request():

        nonlocal request_count
        if request_count >= 100:
            print("Reached request limit. Waiting for 15 minutes...")
            time.sleep(15 * 60)  # Sleep for 15 minutes
            request_count = 0    # Reset the counter after waiting
        
    def request_athlete_profile():

        nonlocal request_count
        sleep_request()

        athlete_url = 'https://www.strava.com/api/v3/athlete' 

        response = requests.get(athlete_url, headers=headers)
        request_count += 1

        try:
            data = response.json()
            print("Extracted athlete profile.")
        except:
            print(f'Error: {response.json()}')
    
        return data
    
    def request_stats():
        
        nonlocal request_count
        sleep_request()
        
        stats_url = f"https://www.strava.com/api/v3/athletes/{ATHLETE_ID}/stats"

        response = requests.get(stats_url, headers=headers)
        request_count += 1

        try:
            data = response.json()
            print("Extracted athlete stats.")
        except:
            print(f'Error: {response.json()}')

        return data
    
    def request_activities():
        
        nonlocal request_count
        activities = []
        page = 1
        per_page = 30

        while True:

            activities_url = f"https://www.strava.com/api/v3/athlete/activities?page={page}&per_page={per_page}"
            response = requests.get(activities_url, headers=headers)
            request_count += 1
            sleep_request()

            if response.status_code != 200:
                print(f"Error: {response.status_code} - {response.text}")
                break

            data = response.json()
            if not data:
                # No more activities to fetch
                break

            activities.extend(data)
            page += 1
            time.sleep(2)

        print("Extracted activities.")
        return activities
    
    def request_comments(activities):

        def comments_per_activity(activity_id):
            
            nonlocal request_count
          
            comments_url = f"https://www.strava.com/api/v3/activities/{activity_id}/comments"

            response = requests.get(comments_url, headers=headers)
            request_count += 1  
            sleep_request() 

            if response.status_code == 200:
                return response.json()
            else:
                response.raise_for_status()
        # --------------------------------------

        all_comments = []
        limit = 0         

        for activity in activities:
            if limit == 100:
                break
            else:
                activity_id = activity['id']
                comments = comments_per_activity(activity_id)
                if comments:
                    all_comments.extend(comments)
                limit += 1   

        print("Extracted comments.")
        return all_comments
    
    ### Start function ###

    athlete = request_athlete_profile()
    stats = request_stats()
    activities = request_activities()
    comments = request_comments(activities)

    json_dict = {
        "athlete": athlete,
        "stats": stats,
        "activities": activities,
        "comments": comments
    }

    for name, data in json_dict.items():
        with open(f"data/raw/{name}.json", 'w') as file:
            json.dump(data, file, indent=4)

    return json_dict

def strava_request_api_data():

    s3_folder = "raw/"
    
    access_token = request_access_token()
    json_dict = request_data(access_token)

    load_data_to_s3(s3, BUCKET_NAME, s3_folder, json_dict)

strava_request_api_data()

    # sns_client = boto3.client('sns')

    # sns_client.publish(
    #     TopicArn=sns_topic_arn,
    #     Message='Data request completed'
    # )
