#!/bin/bash
#
# Builds the spinnaker operator and pushes it to selected repos
#
while [ "$1" != "" ]; do
    case $1 in
    -o|--operator-name)
        shift
        name=$1
        ;;
    -k|--keys-location)
        shift
        keys=$1
        ;;
    -r|--push-redhat)
        pushRh=1
        ;;
    -d|--push-docker)
        pushDock=1
        ;;
    -V|--version)
        shift
        ver=$1
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
  -o|--operator-name=STRING Name of the operator container
  -k|--keys-location=STRING Location of the keys
  -r|--push-redhat          Push to the Red Hat registry
  -d|--push-docker          Push to the Docker registry
  -V|--version=VERSION      Version to tag the image with
  -v|--verbose              Does nothing
  -h|--help                 This usage
  e.g., $0 -o spinnaker-operator -k $HOME/.keys -r -p -V 1.16.0-1
"
}

pushRemote() {
    repo=$1
    user=$2
    credsFile=$3
    image=$4

    cat $credsFile | docker login --username $user --password-stdin $repo
    docker push $image
}

name=${name:-spinnaker-operator}
keys=${keys:-$HOME/.keys}
dfile="build/Dockerfile"
repo="devopsmx"
latest="${repo}/${name}:latest"
image="${repo}/${name}:${ver}"

dockerReg="docker.io"
dockerCredsFile=$keys/${repo}.auth
dockerUser=$repo

rhReg="scan.connect.redhat.com"
rhPid="25590a91-d935-4720-ba5a-3b1756c0add1"
rhImage="${rhReg}/ospid-${rhPid}/${name}:${ver}"
rhUser="unused"
rhCredsFile="${keys}/pidkey-${rhPid}"

gcrReg="gcr.io"
gcrRepo="opsmx-images"
gcrImage="${gcrReg}/${gcrExt}/${name}:${ver}"
gcrUser="opsmxadm@gmail.com"
gcrCredsFile="${keys}/gcr.auth"

if [ -z "$ver" ];then
    usage
    exit 1
fi

cd ..
docker build -t $latest -f ${dfile} .
docker build -t $image -f ${dfile} .
# docker tag $latest $gcrImage
if [ "$pushDock" == "1" ];then
    pushRemote $dockerReg $dockerUser $dockerCredsFile $image
    pushRemote $dockerReg $dockerUser $dockerCredsFile $latest
fi
if [ "$pushRh" == "1" ]; then
    docker tag $latest $rhImage
    pushRemote $rhReg $rhUser $rhCredsFile $rhImage
fi
# pushRemote $gcrRepo $gcrUser $gcrCredsFile $gcrImage
