#!/bin/bash
#
# TODO: cleanup and make it work
#
while [ "$1" != "" ]; do
    case $1 in
    -b|--operator-bundle)
        shift
        location=$1
        ;;
    -u|--quay-user)
        shift
        user=$1
        ;;
    -p|--quay-password)
        shift
        password=$1
        ;;
    -n|--package-name)
        shift
        package=$1
        ;;
    -V|--package-version)
        shift
        version=$1
        ;;
    -h|--help)
        $0
        exit 1
        ;;
    *)
        $0
        exit 1
    esac
    shift
done

usage() {
  echo "Usage: $0 [OPTION...]
  -b|--operator-bundle=DIR  Location of the Operator bundle to upload to Quay
  -n|--poackage-name=STRING The name of the application bundle
  -u|--quay-user=STRING     Username of the quay account to retrieve the auth token
  -p|--quay-password=STRING Password for the quay account to retrieve the auth token
  -V|--version=VERSION      Version of the Operator Application to tag in the upload
  -v|--verbose              Does nothing
  -h|--help                 This usage
  e.g., $0 -b ../bundle -u devopsmx -p 'password' -V 1.16.0 -n open-enterprise-spinnaker
"
}

getToken() {
  user=$1
  pass=$2
  token=$(curl -s -H "Content-Type: application/json" -XPOST https://quay.io/cnr/api/v1/users/login -d '
  {
      "user": {
          "username": "'"${user}"'",
          "password": "'"${pass}"'"
      }
  }')
  tok=$(echo $token | awk -F: '{ print $2 }'| sed -e s/}//)
  if [[ $tok =~ "basic " ]]; then
    echo $tok
  fi
  echo ""
}

x=$(which operator-courier)
if [ "$?" != "0" ];then
    echo "Pushing requires the operator-courier, e.g., pip install operator-courier"
    exit 1
fi
if [ -z "$location" -o -z "$user" -o -z "$package" -o -z "$version" ]; then
  usage
  exit 3
fi

export OPERATOR_DIR=$location
export QUAY_NAMESPACE=$user
export PACKAGE_NAME=$package
export PACKAGE_VERSION=$version
export TOKEN=$(getToken $user $password)
if [ -z "$TOKEN" ]; then
  echo "Empty token, authentication failed!"
  exit 2
fi

operator-courier push \
    "$OPERATOR_DIR" \
    "$QUAY_NAMESPACE" \
    "$PACKAGE_NAME" \
    "$PACKAGE_VERSION" \
    "$TOKEN"
