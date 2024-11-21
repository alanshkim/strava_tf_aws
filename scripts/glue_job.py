import sys
from config.settings import S3_BUCKET_NAME
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.functions import col, avg, count
from awsglue.job import Job  # type: ignore
from awsglue.utils import getResolvedOptions  # type: ignore
from awsglue.context import GlueContext  # type: ignore
from awsglue.dynamicframe import DynamicFrame  # type: ignore

def aggregate_activities(df):

    # Set conditions and aggregations.
    long_run_condition = ((col("sport_type") == "TrailRun") | (col("sport_type") == "Run")) & \
                         (col("elapsed_time") > 60) & (col("distance") > 10)
    
    # Define metrics to aggregate with rounding
    averages = ["distance", "elapsed_time", "total_elevation_gain"]
    average_metrics = [F.round(avg(column), 2).alias(f"avg_{column}") for column in averages]
    
    # Define additional aggregations
    long_run_count = count("sport_type").alias("number_of_long_runs")
    avg_cadence_spm = F.round(avg("steps_per_minute"), 2).alias("avg_cadence_spm")
    avg_speed_mph = F.round(avg("average_speed"), 2).alias("avg_speed_mph")
    avg_heartrate_bpm = F.round(avg("average_heartrate"), 2).alias("avg_heartrate_bpm")
    avg_watts_ftp = F.round(avg("average_watts"), 2).alias("avg_watts_ftp")

    # Apply filter and aggregation
    long_run_df = df.filter(long_run_condition)
    agg_expressions = average_metrics + [long_run_count, avg_cadence_spm, avg_speed_mph, avg_heartrate_bpm, avg_watts_ftp]
    aggregated_df = long_run_df.agg(*agg_expressions)

    return aggregated_df

def main():

    # Initialize Glue and Spark contexts

    args = getResolvedOptions(sys.argv, ["JOB_NAME", "file-name"])
    file_name = args["file-name"]  

    sc = SparkContext()
    glueContext = GlueContext(sc)
    job = Job(glueContext)
    job.init(args["JOB_NAME"], args)

    input_path = f"s3://{S3_BUCKET_NAME}/{file_name}"
    output_path = f"s3://{S3_BUCKET_NAME}/temp/"
    
    connection_opt = {
        "paths": [input_path]
    }
    # Read data from S3
    dynamic_df = glueContext.create_dynamic_frame.from_options(
        connection_type="s3", 
        connection_options=connection_opt, 
        format="json"
    )

    # Convert DynamicFrame to DataFrame for Spark transformations
    df = dynamic_df.toDF()

    # Aggregate the DataFrame
    aggregated_df = aggregate_activities(df)

    # Convert aggregated DataFrame back to DynamicFrame for writing
    aggregated_dynamic_df = DynamicFrame.fromDF(aggregated_df, glueContext, "aggregated_dynamic_df")

    # Write the aggregated DynamicFrame to S3
    glueContext.write_dynamic_frame.from_options(
        aggregated_dynamic_df,
        connection_type="s3",
        connection_options={"path": output_path},
        format="json",
    )

    job.commit()

if __name__ == "__main__":
    main()
