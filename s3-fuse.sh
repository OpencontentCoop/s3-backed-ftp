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
FS_OPTIONS="-o allow_other -o mp_umask='$MP_UMASK' -o umask='$UMASK'"

if [ ! -z $IAM_ROLE ]; then
  FS_OPTIONS="$FS_OPTIONS -o iam_role='$IAM_ROLE'"
fi

if [[ $TRACE ]] ; then
  FS_OPTIONS="$FS_OPTIONS -d -d -f -o f2 -o curldbg"
fi

/usr/local/bin/s3fs $FTP_BUCKET /home/aws/s3bucket $FS_OPTIONS

/usr/local/users.sh

