#!/bin/bash
# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=bash fileencoding=utf-8

[[ $TRACE ]] && set -x

SLEEP_TIME=${SYNC_FREQUENCY:-180}

if [[ -z $S3_DECOUPLED ]]; then
  DO_NOTHING='true'
else
  DO_NOTHING='false'
fi

FTP_ROOT=/home/aws/s3bucket
S3_MOUNTPOINT=/home/s3/s3bucket

while /bin/true; do
  
  sleep $SLEEP_TIME

  if [[ $DO_NOTHING == 'false' ]]; then
    aws s3 sync --only-show-errors --delete ${FTP_ROOT} s3://${FTP_BUCKET}
  fi


done
