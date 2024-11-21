import os
import sys
from awsglue.utils import getResolvedOptions

# Get the required arguments
args = getResolvedOptions(sys.argv, ["JOB_NAME", "file-name"])

# Access 'file-name'
file_name = args["file-name"]
print(f"Processing file: {file_name}")