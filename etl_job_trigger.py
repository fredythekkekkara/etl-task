import boto3

def lambda_handler(event, context):
    glue = boto3.client('glue', region_name='eu-central-1')
    job_name = 'etl-data-job'

    response = glue.start_job_run(
        JobName=job_name
    )

    return {
        'statusCode': 200,
        'body': f'Started Glue job: {job_name}. Job Run ID: {response["JobRunId"]}'
    }
