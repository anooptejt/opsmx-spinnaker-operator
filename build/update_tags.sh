#!/bin/bash
#
# Simple script to update the tags used for the operator, when a new images is made
#
old=$1
new=$2

if [ "$new" == "" ]; then
  echo "$0: <old tag> <new tag>"
  exit 1
fi

pre="spinnaker-operator:"
echo perl -pi -e "s/${pre}${old}/${pre}${new}/g" $(find ../ -type f | xargs grep $old | grep -v git | awk -F: '{ print $1 }')
