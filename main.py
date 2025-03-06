import os
import json
import time
import boto3
import feedparser
from datetime import datetime, timedelta
from discord_webhook import DiscordWebhook, DiscordEmbed

# Configuration
CONFIG_FILE = os.getenv('CONFIG_FILE', 'config.json')

def load_config():
    """Load configuration from config file"""
    try:
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
        
        # Replace environment variable placeholders
        for search in config.get('job_searches', []):
            if 'webhook_url' in search and search['webhook_url'].startswith('${') and search['webhook_url'].endswith('}'):
                env_var = search['webhook_url'][2:-1]
                search['webhook_url'] = os.getenv(env_var, '')
        
        return config
    except Exception as e:
        print(f"Error loading config: {str(e)}")
        # Fallback to environment variables
        return {
            "job_searches": [
                {
                    "keywords": "devops",
                    "location": "stockholm",
                    "webhook_url": os.getenv("STOCKHOLM_WEBHOOK_URL", "")
                },
                {
                    "keywords": "devops",
                    "location": "oslo",
                    "webhook_url": os.getenv("OSLO_WEBHOOK_URL", "")
                }
            ]
        }

# Initialize DynamoDB
def get_dynamodb_table():
    """Get or create DynamoDB table"""
    dynamodb = boto3.resource('dynamodb')
    table_name = 'LinkedInJobsPosted'
    
    try:
        table = dynamodb.Table(table_name)
        # Check if table exists by making a simple call
        table.scan(Limit=1)
        return table
    except:
        print(f"Table {table_name} does not exist or is not accessible")
        return None

def fetch_linkedin_jobs_rss(keywords, location):
    """Fetch LinkedIn jobs using RSS feed"""
    try:
        # Format the RSS feed URL for LinkedIn jobs
        rss_url = (
            f"https://www.linkedin.com/jobs/search/?keywords={keywords}"
            f"&location={location}&trk=public_jobs_jobs-search-bar_search-submit"
            f"&redirect=false&position=1&pageNum=0&f_RSS=true"
        )
        
        # Parse the RSS feed
        feed = feedparser.parse(rss_url)
        
        # Convert feed entries to job objects
        jobs = []
        for entry in feed.entries:
            job = {
                "title": entry.title,
                "link": entry.link,
                "company": entry.get("author", "Unknown Company"),
                "description": entry.get("summary", "No description available"),
                "location": location.capitalize(),
                "date": entry.get("published", datetime.now().strftime("%Y-%m-%d"))
            }
            jobs.append(job)
            
        return jobs
    except Exception as e:
        print(f"Error fetching RSS: {str(e)}")
        return []

def is_job_posted(table, job_id):
    """Check if a job has already been posted"""
    if not table:
        return False
        
    try:
        response = table.get_item(Key={'job_id': job_id})
        return 'Item' in response
    except Exception as e:
        print(f"Error checking DynamoDB: {str(e)}")
        return False

def mark_job_as_posted(table, job_id):
    """Mark a job as posted in DynamoDB"""
    if not table:
        return
        
    try:
        # Set expiration date to 30 days from now (to clean up old entries)
        expires_at = int((datetime.now() + timedelta(days=30)).timestamp())
        
        table.put_item(Item={
            'job_id': job_id,
            'posted_at': datetime.now().isoformat(),
            'expires_at': expires_at
        })
    except Exception as e:
        print(f"Error updating DynamoDB: {str(e)}")

def send_to_discord(job, webhook_url):
    """Send job to Discord using webhooks"""
    if not webhook_url:
        print("No webhook URL provided")
        return None
        
    try:
        webhook = DiscordWebhook(url=webhook_url)
        
        # Create embed
        embed = DiscordEmbed(
            title=job["title"],
            description=job["description"][:4000] if job["description"] else "No description available",
            url=job["link"],
            color="0077B5"  # LinkedIn blue
        )
        
        # Add fields
        embed.add_embed_field(name="Company", value=job["company"], inline=True)
        embed.add_embed_field(name="Location", value=job["location"], inline=True)
        embed.add_embed_field(name="Posted", value=job["date"], inline=True)
        
        # Add footer and timestamp
        embed.set_footer(text="LinkedIn Job Alert")
        embed.set_timestamp()
        
        # Add embed to webhook
        webhook.add_embed(embed)
        
        # Execute webhook
        response = webhook.execute()
        
        # Add a small delay to avoid rate limits
        time.sleep(1)
        
        return response
    except Exception as e:
        print(f"Error sending to Discord: {str(e)}")
        return None

def process_search(table, search):
    """Process a single search configuration"""
    keywords = search["keywords"]
    location = search["location"]
    webhook_url = search["webhook_url"]
    
    print(f"Searching for '{keywords}' in '{location}'...")
    
    # Get jobs from LinkedIn
    jobs = fetch_linkedin_jobs_rss(keywords, location)
    
    jobs_sent = 0
    for job in jobs:
        # Create a unique identifier for this job
        job_id = f"{job['title']}-{job['company']}-{job['link']}"
        
        # Skip if we've already posted this job
        if is_job_posted(table, job_id):
            continue
        
        # Send to Discord
        response = send_to_discord(job, webhook_url)
        
        if response:
            # Mark as posted
            mark_job_as_posted(table, job_id)
            jobs_sent += 1
    
    return jobs_sent

def lambda_handler(event, context):
    """Main Lambda handler function"""
    config = load_config()
    table = get_dynamodb_table()
    total_jobs_sent = 0
    
    for search in config.get("job_searches", []):
        jobs_sent = process_search(table, search)
        total_jobs_sent += jobs_sent
        print(f"Sent {jobs_sent} new job notifications for {search['keywords']} in {search['location']}")
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Successfully sent {total_jobs_sent} new job notifications')
    }

# For local testing
if __name__ == "__main__":
    lambda_handler(None, None)