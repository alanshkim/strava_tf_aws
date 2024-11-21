import json

def extract_data_from_s3(s3, bucket_name, s3_folder, object_keys):

    data_dict = {}

    for key in object_keys:

        file_key = f"{s3_folder}{key}"
        key = key.replace('.json', '') # load function concats '.json. string.

        try:
            response = s3.get_object(Bucket=bucket_name, Key=file_key)
            content = response['Body'].read().decode('utf-8')  # Decode the byte content
            json_data = json.loads(content)
            data_dict[key] = json_data  # Store the content by object key
        except Exception as e:
            print(f"Error fetching {key}: {e}")
            data_dict[key] = None  # Handle the error accordingly

    return data_dict

def load_data_to_s3(s3, bucket_name, s3_folder, data_dict):
    
    for key, data in data_dict.items():

        key = f"{s3_folder}{key}.json"
        data = json.dumps(data).encode('utf-8')


        s3.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=data,
            ContentType='application/json'
        )