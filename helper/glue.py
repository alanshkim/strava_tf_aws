import boto3
import logging
from config.settings import GLUE_JOB_NAME

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

def trigger_glue_job():

    glue_client = boto3.client('glue')

    try:
        response = glue_client.start_job_run(JobName=GLUE_JOB_NAME)
        logger.info(f"Glue job {GLUE_JOB_NAME} started successfully. Job run ID: {response['JobRunId']}")
    except Exception as e:
        logger.error(f"Failed to start Glue job: {str(e)}")
        raise e