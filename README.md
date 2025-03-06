# LinkedIn Jobs Discord Bot

A Discord bot that automatically fetches LinkedIn job listings with custom search parameters and posts them to your Discord channels. The bot searches for specific job keywords in selected locations and sends updates via Discord webhooks.

![LinkedIn to Discord Bot](https://media.discordapp.net/attachments/placeholder/linkedin-jobs-preview.png)

## Features

- 🔍 Search for jobs with custom keywords (e.g., "devops") and locations (e.g., "stockholm", "oslo")
- 📊 Post new job listings to dedicated Discord channels via webhooks
- 🔄 Run automatically on a schedule (every day at 9 AM UTC by default)
- 💾 Track posted jobs to avoid duplicates
- ☁️ Easy deployment to AWS using Terraform
- 💰 Designed to stay within AWS Free Tier limits

## Setup Guide

### Prerequisites

- [Python 3.9+](https://www.python.org/downloads/)
- [Terraform](https://www.terraform.io/downloads.html)
- [AWS Account](https://aws.amazon.com/) (Free Tier eligible)
- [Discord Server](https://discord.com/) with admin permissions

### Step 1: Create Discord Webhooks

1. Open your Discord server
2. Go to the channel where you want job listings to appear
3. Click the ⚙️ (settings) icon → Integrations → Webhooks
4. Click "New Webhook"
5. Give it a name (e.g., "Stockholm DevOps Jobs")
6. Copy the webhook URL - you'll need this later
7. Repeat for each location you want to track

### Step 2: Clone this Repository

```bash
git clone https://github.com/your-username/linkedin-jobs-discord-bot.git
cd linkedin-jobs-discord-bot
```

### Step 3: Quick Setup

Use the setup script to create the necessary files:

```bash
# Make setup script executable
chmod +x scripts/setup.sh

# Run setup script
./scripts/setup.sh
```

The script will:
1. Create a virtual environment
2. Install dependencies
3. Create Lambda layer ZIP file
4. Prompt for your Discord webhook URLs
5. Create configuration files

### Step 4: Test Locally (Optional)

Before deploying, you can test the bot locally:

```bash
# Activate virtual environment
source venv/bin/activate

# Run local test script
python scripts/local_test.py

# Or run the main script directly
python main.py
```

### Step 5: Deploy with Terraform

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Preview what will be created
terraform plan

# Deploy resources
terraform apply
```

Confirm the deployment by typing `yes`.

### Step 6: Verify Deployment

1. Check your Discord channels for test messages
2. The bot will now run automatically according to the schedule (daily at 9 AM UTC by default)
3. You can run it manually from the AWS Lambda console if you want

## Configuration

### Customize Job Searches

Edit `config.json` to modify your search parameters:

```json
{
  "job_searches": [
    {
      "keywords": "devops",
      "location": "stockholm",
      "webhook_url": "${STOCKHOLM_WEBHOOK_URL}"
    },
    {
      "keywords": "python developer",
      "location": "oslo",
      "webhook_url": "${OSLO_WEBHOOK_URL}"
    }
  ]
}
```

You can add as many search configurations as you need.

### Modify Schedule

To change how often the bot checks for jobs:

1. Edit `terraform/main.tf`
2. Find the `aws_cloudwatch_event_rule` resource
3. Modify the `schedule_expression` value (uses [cron syntax](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html#eb-cron-expressions))

Example for running twice a day at 9 AM and 5 PM UTC:
```
schedule_expression = "cron(0 9,17 * * ? *)"
```

## AWS Free Tier Usage

This bot is designed to stay within AWS Free Tier limits:
- **Lambda**: Free Tier includes 1M free requests and 400,000 GB-seconds per month
- **DynamoDB**: Free Tier includes 25 GB of storage
- **CloudWatch Events**: No charge for scheduled events

Running once per day with minimal processing, this bot should cost $0 within the Free Tier.

### Cost Monitoring

1. Set up AWS Budget Alerts:
   - Go to AWS Billing Dashboard
   - Click "Budgets" → "Create budget"
   - Select "Zero spend budget" to get alerts on any charges
   - Set email notifications

## Troubleshooting

- **No jobs appearing?**
  - Check that your webhook URLs are correct
  - Verify your search terms aren't too specific
  - Check AWS Lambda CloudWatch logs for errors

- **Duplicate jobs appearing?**
  - The DynamoDB table might need to be cleared
  - Run: `aws dynamodb delete-table --table-name LinkedInJobsPosted` and redeploy

- **Terraform errors?**
  - Make sure you have the latest Terraform version
  - Check that your AWS credentials are set up correctly

## Uninstalling

To remove all AWS resources:

```bash
cd terraform
terraform destroy
```

Confirm by typing `yes`.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.