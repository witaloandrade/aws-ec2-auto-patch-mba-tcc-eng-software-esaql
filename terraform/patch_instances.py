import boto3
from datetime import datetime, timezone
import logging
from typing import List, Dict, Any

patch_tag_key = 'auto-patch'

# Configure logging
logger = logging.getLogger()
logger.setLevel("INFO")
# Used to print logs to local execution
# logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def get_week_of_month(date: datetime) -> int:
    """
    Get the week number of the week for the specified date.
    """
    first_day = date.replace(day=1)
    return (date.day + first_day.weekday() - 1) // 7 + 1

def list_ec2_instances_by_tag() -> List[str]:
    """
    List EC2 instances with the current week-day-hour tag.
    """
    now = datetime.now(timezone.utc)
    logger.info(f'Current UTC time is {now}')
    
    week_name = {
        1: 'first',
        2: 'second',
        3: 'third',
        4: 'fourth',
        5: 'fifth'
    }
    
    day = now.strftime('%A').lower()
    week = week_name[get_week_of_month(now)]
    hour = now.strftime('%H').zfill(2)
    
    tag_value = f"{week}-{day}-{hour}"
    logger.info(f'Current Patch Tag Value is {tag_value}')
    print(f'Current Patch Tag Value is {tag_value}')
    
    session = boto3.Session()
    ec2 = session.client('ec2')
    logger.info("Listing EC2 instances with the current week-day-hour tag...")
    
    try:
        response = ec2.describe_instances(
            Filters=[
                {
                    'Name': f'tag:{patch_tag_key}',
                    'Values': [tag_value]
                },
                {
                    'Name': 'instance-state-name',
                    'Values': ['running']
                }
            ]
        )
    except Exception as e:
        logger.error(f"Error describing instances: {e}")
        return []
    
    instance_ids = [
        instance['InstanceId']
        for reservation in response['Reservations']
        for instance in reservation['Instances']
    ]
    logger.info("Found instances: %s to be patched", instance_ids)
    return instance_ids

def patch_instances(instances: List[str]) -> None:
    """
    Patch the specified EC2 instances using AWS Systems Manager.
    """
    session = boto3.Session()
    ssm = session.client('ssm')
    logger.info(f'Patching instances {instances}')
    for instance in instances:
        logger.info(f'Patching instance {instance}')
        try:
            response = ssm.send_command(
                InstanceIds=[instance],
                DocumentName='AWS-RunPatchBaseline',
                Comment=instance,
                Parameters={'Operation': ['Install']}
            )
            if response['ResponseMetadata']['HTTPStatusCode'] == 200:
                logger.info(f"Success to send command to patch instance {instance}: {response['Command']['CommandId']}")
            else:
                logger.error(f"Failed to send command to instance {instance}")
        except Exception as e:
            logger.error(f"Error sending command to instance {instance}: {e}")

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler function.
    """
    logger.info("Event: %s", event)
    instances = list_ec2_instances_by_tag()
    if instances:
        logger.info("EC2 instances with the current week-day-hour tag: %s", instances)
        logger.info("Executing command to patch instances...")
        patch_instances(instances)
    else:
        logger.info("No EC2 instances with the current week-day-hour tag found.")
    return {
        'statusCode': 200,
        'body': 'Execution completed.'
    }

lambda_handler({}, None)
