import os
import boto3
import datetime
import logging
from helper.glue import trigger_glue_job
from helper.s3_data_migration import extract_data_from_s3, load_data_to_s3

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

s3 = boto3.client('s3')

def convert_stats(stats):

    def seconds_to_hms(seconds):
        return str(datetime.timedelta(seconds=seconds))
    
    for key in stats.keys():

        if "distance" in stats[key]:         
            stats[key]["distance"] = round(stats[key]["distance"] / 1609.34, 2)  # Meters to miles
        if "moving_time" in stats[key]:
            stats[key]["moving_time"] = seconds_to_hms(stats[key]["moving_time"])  # Seconds to hh:mm:ss
        if "elapsed_time" in stats[key]:
            stats[key]["elapsed_time"] = seconds_to_hms(stats[key]["elapsed_time"])  # Seconds to hh:mm:ss
        if "elevation_gain" in stats[key]:
            stats[key]["elevation_gain"] = round(stats[key]["elevation_gain"] * 3.28084, 1)  # Meters to feet

    return stats

def convert_activities(activities):
    
    def seconds_to_minutes(seconds):
        return round(seconds / 60, 2)

    def mps_to_mph(mps):
        return round(mps * 2.23694, 1)

    # Filter out activities that are Weight Training.
    run_activities = [activity for activity in activities if activity.get('type') != 'WeightTraining']

    for activity in run_activities:
        activity['distance'] = round(activity['distance'] / 1609.34, 2)
        activity['total_elevation_gain'] = round(activity['total_elevation_gain'] * 3.28084, 1)
        activity['moving_time'] = seconds_to_minutes(activity['moving_time'])
        activity['elapsed_time'] = seconds_to_minutes(activity['elapsed_time'])
        activity['average_speed'] = mps_to_mph(activity['average_speed'])
        activity['max_speed'] = mps_to_mph(activity['max_speed'])
        # Garmin metrics. Some activities were recorded without it.
        if 'average_cadence' in activity:
            activity['steps_per_minute'] = round(activity['average_cadence'] * 2, 0)
        if 'elev_high' in activity:
            activity['elev_high'] = round(activity['elev_high'] * 3.28084, 1)
        if 'elev_low' in activity:    
            activity['elev_low'] = round(activity['elev_low'] * 3.28084, 1)

    return run_activities

def lambda_handler(event, handler):
    
    BUCKET_NAME = os.environ['BUCKET_NAME']
    OBJECT_KEYS = os.environ['OBJECT_KEYS'].split(', ') # Keys stored as a list.

    processed_dict = {} 

    s3_folder = "raw/"

    print("Starting data extraction from s3")
    s3_data = extract_data_from_s3(s3, BUCKET_NAME, s3_folder, OBJECT_KEYS)
    print("Data extraction successful")

    STATS = s3_data['stats']
    ACTIVITIES = s3_data['activities']

    stats = convert_stats(STATS)
    processed_dict['stats'] = stats
    activities = convert_activities(ACTIVITIES)
    processed_dict['activities'] = activities
    print("Data transformation successful")

    print("Loading processed data to s3...")

    s3_folder = "processed/"
    load_data_to_s3(s3, BUCKET_NAME, s3_folder, processed_dict)

    trigger_glue_job()
    
    return {
        'statusCode': 200,
        'body': 'ETL and Glue job trigger successful'
    }