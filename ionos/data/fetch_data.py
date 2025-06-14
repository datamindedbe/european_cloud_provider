import httpx
import yaml
import os
from dotenv import load_dotenv
import io
import csv
import boto3
from botocore.client import Config
from pathlib import Path
from datetime import date, datetime, timezone
import time

env_path = Path(__file__).resolve().parents[2] / ".env"
load_dotenv(dotenv_path=env_path)

with open("config.yml", "r") as f:
    config = yaml.safe_load(f)

#------------ Config -----------------------------------

bucket_name = 'dataminded-terraform-test'
dataminded = config["companies"]["data-minded"]["id"]
dataminded_name = "data-minded"


# ------------------------------------------------------

def s3_client(config):
    os.environ['AWS_REQUEST_CHECKSUM_CALCULATION'] = 'WHEN_REQUIRED'
    s3 = boto3.client('s3',
                      endpoint_url = config["s3"]["endpoint"],
                      region_name = config["s3"]["region"],
                      aws_access_key_id = os.getenv("access_key"),
                      aws_secret_access_key = os.getenv("secret_key"),
                      config = Config(signature_version='s3v4')
                     )
    return s3
    

def object_name(filename):
    path = f"raw/company/{filename}/{date.today().strftime("%Y/%m/%d")}/{filename}_{datetime.now(timezone.utc).strftime("%Y_%m_%d_%H_%M_%S")}.csv"
    return path


def load_api_key():
    api_key = os.getenv("RAPIDAPI_KEY")
    return api_key



def get_company_details(company_id):
    base_url = config["api"]["base_url"]
    params = {"id": company_id}
    headers = {
        "x-rapidapi-host": config["api"]["host"],
        "x-rapidapi-key": load_api_key(),
    }
    response = httpx.get(base_url, params=params, headers=headers)
    return response


def get_company_posts(company_name):
    base_url = config["api_posts"]["base_url"]
    params = {"username": company_name}
    headers = {
        "x-rapidapi-host": config["api_posts"]["host"],
        "x-rapidapi-key": load_api_key(),
    }
    response = httpx.get(base_url, params=params, headers=headers)
    return response


def save_file_to_s3_details(file, s3_client, bucket_name, object_name):
    data = file.json().get("data", {})
    headquarter = data.get("headquarter", {})
    founded = data.get("founded", {})

    company_info = {
        "id": data.get("id"),
        "name": data.get("name"),
        "global_name": data.get("universalName"),
        "url_linkedin": data.get("linkedinUrl"),
        "tagline": data.get("tagline"),
        "description": data.get("description"),
        "type": data.get("type"),
        "employees_counter": data.get("staffCount"),
        "hq_area": headquarter.get("geographicArea"),
        "hq_country": headquarter.get("country"),
        "hq_city": headquarter.get("city"),
        "hq_zip_code": headquarter.get("postalCode"),
        "industries": data.get("industries"),
        "specialities": data.get("specialities"),
        "website": data.get("website"),
        "founded": founded.get("year"),
        "followers_counter": data.get("followerCount"),
    }

    csv_buffer = io.StringIO()
    writer = csv.DictWriter(csv_buffer, fieldnames=company_info.keys())
    writer.writeheader()
    writer.writerow(company_info)
    
    s3_client.put_object(
        Bucket=bucket_name,
        Key=object_name,
        Body=csv_buffer.getvalue().encode('utf-8')
    )


def save_file_to_s3_posts(fetch_posts, s3_client, bucket_name, object_name):
    posts = fetch_posts.json().get("data", [])
    rows = []
    for post in posts:
        urn = post.get("company", {}).get("urn")
        text = post.get("text")
        likes_count = post.get("likeCount")
        comments_count = post.get("commentsCount")
        interest_count = post.get("InterestCount")
        empathy_count = post.get("empathyCount")
        reposts_count = post.get("repostsCount")
        posted_at = post.get("postedAt")
        timestamp_posted = post.get("postedDate")
        url = post.get("shareUrl")    
        
        rows.append({
            "id": urn,
            "content": text,
            "likes_count": likes_count,
            "comments_count": comments_count,
            "interest_count": interest_count,
            "empathy_count": empathy_count,
            "reposts_count": reposts_count,
            "posted_at": posted_at,
            "timestamp_posted": timestamp_posted,
            "url": url        
        })

    csv_buffer = io.StringIO()
    writer = csv.DictWriter(csv_buffer, fieldnames=rows[0].keys())
    writer.writeheader()
    writer.writerows(rows)
    
    s3_client.put_object(
        Bucket=bucket_name,
        Key=object_name,
        Body=csv_buffer.getvalue().encode('utf-8')
    )

#fetch = get_company_details(dataminded)
#save_file_to_s3_details(fetch,s3_client(config),bucket_name,object_name("dataminded-profile"))


max_attempts = 3
attempt = 0
success = False

while attempt < max_attempts and not success:
    try:
        fetch_posts = get_company_posts(dataminded_name)
        save_file_to_s3_posts(fetch_posts, s3_client(config), bucket_name, object_name("dataminded-posts"))
        print(f"✅ Success on attempt {attempt + 1}")
        success = True
    except Exception as e:
        attempt += 1
        print(f"⚠️ Attempt {attempt} failed: {e}")
        if attempt >= max_attempts:
            print("❌ Max attempts reached. Exiting.")
        else:
            time.sleep(10)  # Optional delay between attempts
