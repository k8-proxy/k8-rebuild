#!/bin/bash
EXPORT_ID=$(cat out.json | jq -r .[].ExportTaskId)
echo $EXPORT_ID
# increase file size until 1KB
until [ "$RESPONSE" = "completed" ]
do
  RESPONSE=$(aws ec2 describe-export-tasks --export-task-ids $EXPORT_ID | jq -r '.ExportTasks[].State')
  if [ "$RESPONSE" != "exit" ]; then
    echo "OVA export in progress..."
    sleep 30
  fi
done

echo "Upload Completed !!!"

BUCKET=$(cat packer/ova-export.json | jq -r .S3Bucket)

OBJECT="$(aws s3 ls $BUCKET/vms/SOW-REST/ | sort | tail -n 1 | awk '{print $4}')"
aws s3 mv s3://${BUCKET}/vms/SOW-REST/${OBJECT} s3://${BUCKET}/vms/SOW-REST/${OVA_NAME}

# Uncomment to import OVA to AWS

# cat > packer/containers.json <<EOF
# [
#     {
#       "Description": "filedrop OVA",
#       "Format": "ova",
#       "UserBucket": {
#           "S3Bucket": "glasswall-sow-ova",
#           "S3Key": "vms/SOW-REST/${OVA_NAME}"
#       }
#     }
# ]
# EOF
# IMPORT_TASK=$(aws ec2 import-image --description "k8-rebuild-test" --disk-containers "file://packer/containers.json")
# IMPORT_ID=$(echo $IMPORT_TASK | jq -r .ImportTaskId)
# until [ "$RESPONSE" = "completed" ]
# do
#   RESPONSE=$(aws ec2 describe-import-image-tasks --import-task-ids $IMPORT_ID | jq -r '.ImportImageTasks[0].Status')
#   StatusMessage=$(aws ec2 describe-import-image-tasks --import-task-ids $IMPORT_ID | jq -r '.ImportImageTasks[0].StatusMessage')
#   if [ "$RESPONSE" == "deleted" ]; then
#     echo "Failed to import OVA"
#     echo "OVA Import status is $RESPONSE"
#     echo "Status message is $StatusMessage"
#     exit -1
#   elif [ "$RESPONSE" == "active" ]; then
#     echo "OVA Import status is $RESPONSE"
#     echo "Status message is $StatusMessage"
#     sleep 30
#   fi
# done
