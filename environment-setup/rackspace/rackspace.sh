#!/usr/bin/env bash
# See USAGE to see arguments available

echo "ALARM!! THIS FUNCTIONALITY HASN'T BEEN IMPLEMENTED YET"

USAGE="Arguments available:
   Argument                    Functionality                                   Required argument   Default value
   -h, --help                  show help                                       -                   -
   -v, --verbose               print all logs available                        false               false
   -f, --force, --no-force     force ec2 instance to be recreated  if exist    false               true
   -e, --env                   tag for ec2 containing environment name         false               qa
   -c, --container             tag for ec2 containing container name           true                -
   -d, --domain                domain name to be updated with ec2 instance IP  true                -
   -a, --ami                   ami id for instance                             false               ami-02eac2c0129f6376b (CentOS Linux 7 x86_64)
   -k, --key                   AWS .pem key file                               true                -
   -r, --region                AWS region to work with                         false               us-east-1
   -c, --cpu                   AWS cpu                                         false               t2.medium
"


# ------------------------------------------------------
# Collect parameters
SHORT=vfhe:c:d:a:k:r:c:
LONG=verbose,force,no-force,help,env:,container:,domain:,ami:,key:,region:,cpu:
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

# set initial values
VERBOSE=false
FORCE=true
ENV=qa
CONTAINER=
DOMAIN=
AMI_ID=ami-02eac2c0129f6376b
KEY_FILE=
REGION=us-east-1
CPU=t2.medium

# extract options and their arguments into variables
while true ; do
  case "$1" in
    -v | --verbose )
      VERBOSE=true
      shift
      ;;
    -f | --force )
      FORCE=true
      shift
      ;;
    --no-force )
      FORCE=false
      shift
      ;;
    -h | --help )
      echo "$USAGE"
      exit
      ;;
    -e | --env )
      ENV="$2"
      shift 2
      ;;
    -c | --container )
      CONTAINER="$2"
      shift 2
      ;;
    -d | --domain )
      DOMAIN="$2"
      shift 2
      ;;
    -a | --ami )
      AMI_ID="$2"
      shift 2
      ;;
    -k | --key )
      KEY_FILE="$2"
      shift 2
      ;;
    -r | --region )
      REGION="$2"
      shift 2
      ;;
    -c | --cpu )
      CPU="$2"
      shift 2
      ;;
    -- )
      shift
      break
      ;;
    *)
      echo "Error in argument parsing"
      exit 1
      ;;
  esac
done
#Check required variables set
if [ -z "$CONTAINER" ] ; then echo "container name argument isn't presented. Use -h to see arguments available." >&2 ; exit 1 ; fi
if [ -z "$DOMAIN" ] ; then echo "domain name argument isn't presented. Use -h to see arguments available." >&2 ; exit 1 ; fi
if [ -z "$KEY_FILE" ] ; then echo "key file argument isn't presented. Use -h to see arguments available." >&2 ; exit 1 ; fi

# Print the variables
echo "Entered arguments:"
echo "VERBOSE = $VERBOSE"
echo "FORCE = $FORCE"
echo "ENV = $ENV"
echo "CONTAINER = $CONTAINER"
echo "DOMAIN = $DOMAIN"
echo "AMI_ID = $AMI_ID"
echo "KEY_FILE = $KEY_FILE"
echo "REGION = $REGION"
echo "CPU = $CPU"

YUM_PARAMS=()
CURL_PARAMS=()
PIP_PARAMS=()
YUM_PARAMS+=("-y")
YUM_PARAMS+=("-e 0")
[[ $VERBOSE == "false" ]] && YUM_PARAMS+=("-q"); CURL_PARAMS+=("-s"); PIP_PARAMS+=("-q")
echo
#### Isn't implemented for now
# remove exit in future
exit


# ------------------------------------------------------
# install AWS CLI
echo "Install AWS CLI"
if hash aws 2>/dev/null; then
   echo "AWS CLI is already installed"
else
   yum install "${YUM_PARAMS[@]}" curl
   curl "${CURL_PARAMS[@]}" -O https://bootstrap.pypa.io/get-pip.py
   yum install "${YUM_PARAMS[@]}" python3
   python3 get-pip.py
   yum install "${YUM_PARAMS[@]}" groff
   pip3 install "${PIP_PARAMS[@]}" awscli
fi
echo

# ------------------------------------------------------
# configure AWS CLI
echo "Configure AWS CLI"
aws configure set aws_access_key_id ${AWS_KEY}
aws configure set aws_secret_access_key ${AWS_SECRET}
aws configure set region "${REGION}"
aws configure set ouput text
echo

# ------------------------------------------------------
# check whether instance exists and runs
echo "Search for existing instances with same parameters"
FILTERS="Name=tag:Name,Values=${DOMAIN} Name=tag:env,Values=${ENV} Name=tag:container,Values=${CONTAINER}"
EXISTING_INSTANCE_IDS=
#### Isn't implemented for now
#### `aws ec2 describe-instances --filters ${FILTERS} --output text --query Reservations[*].Instances[*].[InstanceId]`


if [[ "$FORCE" == true ]]; then
   echo "Found instances with required arguments: ${EXISTING_INSTANCE_IDS}"
   for instance_id in ${EXISTING_INSTANCE_IDS}
   do
      INSTANCE_STATUS_CMD="aws ec2 describe-instance-status --instance-ids ${instance_id} --include-all-instance  --output text --query InstanceStatuses[*].InstanceState.Name"
      INSTANCE_STATUS=`${INSTANCE_STATUS_CMD}`
      if [[ "$INSTANCE_STATUS" == "running" ]]; then
         echo "Shutting down instance ${instance_id}"
         INSTANCE_STATUS=`aws ec2 stop-instances --instance-ids ${instance_id} --force --output text --query StoppingInstances[*].CurrentState.Name`
         while [[ "$INSTANCE_STATUS" != "stopped" ]];
         do
            echo "INSTANCE_STATUS = $INSTANCE_STATUS"
            sleep 2
            INSTANCE_STATUS=`${INSTANCE_STATUS_CMD}`
         done
         echo "Instance ${instance_id} is stopped"
      fi

      echo "Terminating instance ${instance_id}"
      INSTANCE_STATUS=`aws ec2 terminate-instances --instance-ids ${instance_id} --output text --query TerminatingInstances[*].CurrentState.Name`
      while [[ "$INSTANCE_STATUS" != "terminated" ]];
      do
         echo "INSTANCE_STATUS = $INSTANCE_STATUS"
         sleep 2
         INSTANCE_STATUS=`${INSTANCE_STATUS_CMD}`
      done
      echo "Instance ${instance_id} is terminated"
   done
elif [[ -n "$EXISTING_INSTANCE_IDS" ]]; then
   echo "found instances with required arguments: ${EXISTING_INSTANCE_IDS}"
   for instance_id in ${EXISTING_INSTANCE_IDS}
   do
      INSTANCE_STATUS_CMD="aws ec2 describe-instance-status --instance-ids ${instance_id} --include-all-instance  --output text --query InstanceStatuses[*].InstanceState.Name"
      INSTANCE_STATUS=`${INSTANCE_STATUS_CMD}`
      if [[ "$INSTANCE_STATUS" == "terminated" ]] || [[ "$INSTANCE_STATUS" == "terminating" ]];  then
         echo "Instance ${instance_id} is terminated"
      elif [[ "$INSTANCE_STATUS" != "running" ]]; then
         echo "Starting instance ${instance_id}"
         aws ec2 start-instances --instance-ids ${instance_id} --output text
         while [[ "$INSTANCE_STATUS" != "running" ]];
         do
            echo "INSTANCE_STATUS = $INSTANCE_STATUS"
            sleep 2
            INSTANCE_STATUS=`${INSTANCE_STATUS_CMD}`
         done
        echo "Instance ${instance_id} is running"

        exit 
      elif [[ "$INSTANCE_STATUS" == "running" ]]; then
        echo "Instance ${instance_id} is already running"

        exit 
      fi

   done
fi

echo


# ------------------------------------------------------
# run new instance
echo "Run new instance with provided arguments and security groups sg-06403dbdfc3d53c09 sg-0937c8a0a0134491d sg-0aeafebedb8b9d34d in subnet subnet-0b2f0f5dd2a0a07d9"
TAG_SPEC="ResourceType=instance,Tags=[{Key=Name,Value=${DOMAIN}},{Key=env,Value=${ENV}},{Key=container,Value=${CONTAINER}},{Key=test,Value=TEST}]"
instanceId=
#### Isn't implemented for now
# `aws ec2 run-instances \
#                  --image-id ${AMI_ID} \
#                  --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=40}' \
#                  --count 1 \
#                  --instance-type ${CPU} \
#                  --key-name ${KEY_FILE} \
#                  --security-group-ids sg-0d08c8f889a9beb76 sg-06403dbdfc3d53c09 sg-0937c8a0a0134491d sg-0aeafebedb8b9d34d \
#                  --subnet-id subnet-0b2f0f5dd2a0a07d9 \
#                  --tag-specifications ${TAG_SPEC}\
#                  --query 'Instances[0].InstanceId' \
#                  --output text`

IP_ADDRESS=
#### Isn't implemented for now
# `aws ec2 describe-instances --instance-ids ${instanceId} --output text --query Reservations[*].Instances[*].[PrivateIpAddress]`
echo "Created new instance $instanceId with IP $IP_ADDRESS"
#EXISTING_INSTANCE_IDS=${aws ec2 describe-instances --filters ${FILTERS} --query Reservations[*].Instances[*].[InstanceId]}

echo "Update route for provided domain exist"
RECORD_SET=
#### Isn't implemented for now
# `aws route53 list-resource-record-sets --hosted-zone-id Z3R2PID5NAV5C --output text --query "ResourceRecordSets[?Name=='${DOMAIN}.qa.sli.io.']"`
COMMENT="Update existing record set"
ACTION="UPSERT"
if [[ -z "$RECORD_SET" ]]; then
   COMMENT="Create new record set"
   ACTION="CREATE"
fi
CHANGE_BATCH="{
  \"Comment\": \"${COMMENT}\",
  \"Changes\": [
    {
      \"Action\": \"${ACTION}\",
      \"ResourceRecordSet\": {
        \"Name\": \"${DOMAIN}.qa.sli.io.\",
        \"Type\": \"A\",
        \"TTL\":300,
        \"ResourceRecords\": [
          {
            \"Value\": \"${IP_ADDRESS}\"
          }
        ]
      }
    }
  ]
}"

#### Isn't implemented for now
# aws route53 change-resource-record-sets --hosted-zone-id  Z3R2PID5NAV5C --change-batch "${CHANGE_BATCH}"

exit 

#### Isn't implemented for now

echo "Wait for instance statuses OK"
INSTANCE_STATUS_CMD="aws ec2 describe-instance-status --instance-ids ${instanceId} --include-all-instance  --output text --query InstanceStatuses[*].InstanceStatus.Status"
INSTANCE_STATUS=`${INSTANCE_STATUS_CMD}`
while [[ "$INSTANCE_STATUS" != "ok" ]];
do
    echo "INSTANCE_STATUS = $INSTANCE_STATUS"
    sleep 2
       INSTANCE_STATUS=`${INSTANCE_STATUS_CMD}`
done
echo "Instance status for instance ${instanceId} is ok"

INSTANCE_STATUS_CMD="aws ec2 describe-instance-status --instance-ids ${instanceId} --include-all-instance  --output text --query InstanceStatuses[*].SystemStatus.Status"
INSTANCE_STATUS=`${INSTANCE_STATUS_CMD}`
while [[ "$INSTANCE_STATUS" != "ok" ]];
do
    echo "INSTANCE_STATUS = $INSTANCE_STATUS"
    sleep 2
       INSTANCE_STATUS=`${INSTANCE_STATUS_CMD}`
done
echo "System status for instance ${instanceId} is ok"

echo "Setup is required"

echo "Done"