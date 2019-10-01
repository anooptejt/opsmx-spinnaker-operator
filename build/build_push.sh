#!/bin/bash
#
# Builds the spinnaker operator and pushes it to selected repos
#
name="spinnaker-operator"
ver="1.16.0-1"
dfile="build/Dockerfile"
repo="zappo"
keys=$HOME/.keys
latest="${repo}/${name}:latest"
image="${repo}/${name}:${ver}"

rhelReg="scan.connect.redhat.com"
rhelPid="25590a91-d935-4720-ba5a-3b1756c0add1"
rhelImage="${rhelReg}/ospid-${rhelPid}/${name}:${ver}"
rhelUser="unused"
rhelCredsFile="${keys}/pidkey-${rhelPid}"

gcrReg="gcr.io"
gcrRepo="opsmx-images"
gcrImage="${gcrReg}/${gcrExt}/${name}:${ver}"
gcrUser="opsmxadmn@gmail.com"
gcrCredsFile="${keys}/gcr.auth"

pushRemote() {
  repo=$1
  user=$2
  credsFile=$3
  image=$4

  store="{ \"ServerURL\": \"$rhelRepo\", \"Username\": \"$user\", \"Secret\": \"$(cat ${credsFile})\"}"
  store=$(echo $store | sed -e s/\'/\"/g)
  docker-credential-secretservice store <<_EOF
  $store
_EOF
  docker push $image
}

cd ..
docker build -t $latest -f ${dfile} .
docker build -t $image -f ${dfile} .
docker tag $latest $rhelImage
# docker tag $latest $gcrImage

docker push $latest
docker push $image

exit 0

pushRemote $rhelRepo $rhelUser $rhelCredsFile $rhelImage
pushRemote $gcrRepo $gcrUser $gcrCredsFile $gcrImage
