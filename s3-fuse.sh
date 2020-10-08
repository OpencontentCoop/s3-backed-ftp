#!/bin/bash
# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=bash fileencoding=utf-8

[[ $TRACE ]] && set -x

# Check first if the required FTP_BUCKET variable was provided, if not, abort.
if [ -z $FTP_BUCKET ]; then
  echo "You need to set BUCKET environment variable. Aborting!"
  exit 1
fi

# Then check if there is an IAM_ROLE provided, if not, check if the AWS credentials were provided.
if [ -z $IAM_ROLE ]; then
  echo "You did not set an IAM_ROLE environment variable. Checking if AWS access keys where provided ..."
fi

# Abort if the AWS_ACCESS_KEY_ID was not provided if an IAM_ROLE was not provided neither.
if [ -z $IAM_ROLE ] &&  [ -z $AWS_ACCESS_KEY_ID ]; then
  echo "You need to set AWS_ACCESS_KEY_ID environment variable. Aborting!"
  exit 1
fi

# Abort if the AWS_SECRET_ACCESS_KEY was not provided if an IAM_ROLE was not provided neither. 
if [ -z $IAM_ROLE ] && [ -z $AWS_SECRET_ACCESS_KEY ]; then
  echo "You need to set AWS_SECRET_ACCESS_KEY environment variable. Aborting!"
  exit 1
fi

# If there is no IAM_ROLE but the AWS credentials were provided, then set them as the s3fs credentials.
if [ -z $IAM_ROLE ] && [ ! -z $AWS_ACCESS_KEY_ID ] && [ ! -z $AWS_SECRET_ACCESS_KEY ]; then
  #set the aws access credentials from environment variables
  echo $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY > ~/.passwd-s3fs
  chmod 600 ~/.passwd-s3fs
fi

# Update the vsftpd.conf file to include the IP address if running on an EC2 instance
if curl -s http://ifconfig.co > /dev/null ; then
  IP=$(curl -s http://ifconfig.co)
  sed -i "s/^pasv_address=.*/pasv_address=$IP/" /etc/vsftpd.conf
else
  exit 1
fi

if [[ ! -z $BANNER ]]; then
  sed -i "s/^ftpd_banner=.*/ftpd_banner=$BANNER/" /etc/vsftpd.conf
fi

# start s3 fuse
# Code above is not needed if the IAM role is attaced to EC2 instance 
# s3fs provides the iam_role option to grab those credentials automatically
MP_UMASK=0022
UMASK=0002
FS_OPTIONS="-o allow_other -o mp_umask=$MP_UMASK -o umask=$UMASK"

if [ ! -z $IAM_ROLE ]; then
  FS_OPTIONS="$FS_OPTIONS -o iam_role='$IAM_ROLE'"
fi

if [[ $TRACE ]] ; then
  FS_OPTIONS="$FS_OPTIONS -d -d -f -o f2 -o curldbg"
fi

S3_MOUNTPOINT=/home/aws/s3bucket
[[ ! -d $S3_MOUNTPOINT ]] && mkdir -p $S3_MOUNTPOINT
[[ ! -d ${S3_MOUNTPOINT}/ftp-users ]] && mkdir -p ${S3_MOUNTPOINT}/ftp-users

if [[ -n $S3_DECOUPLED ]]; then
  echo "S3 Fuse mount not required, a periodic s3-sync will be launched"
  sleep 5
  exit 0
fi

/usr/local/bin/s3fs $FTP_BUCKET $S3_MOUNTPOINT $FS_OPTIONS

if [[ $? -gt 0 ]]; then
  echo "ERROR mounting '$FTP_BUCKET' in '$S3_MOUNTPOINT', cannot continue"
  exit 1
fi  

MOUNT_TIMEOUT=10
for ((i = 1; i <= $MOUNT_TIMEOUT; i++)); do
  if $(mount | egrep -q '^s3fs'); then
     echo "SUCCESS, mounted '$FTP_BUCKET'!"
     break
  else
    echo "No s3fs filesystem found, s3fs mount of '$FTP_BUCKET' is still connecting, waiting..."
    sleep 1
  fi
done

if ! $(mount | egrep -q '^s3fs'); then
  echo "No s3fs filesystem found, s3fs mount of '$FTP_BUCKET' in '$S3_MOUNTPOINT' probably failed"
  exit 2
fi

/usr/local/users.sh

