#!/bin/bash
#
# Builds the spinnaker operator and pushes it to selected repos
#
name="spinnaker-operator"
ver="1.15.1-4"
dfile="build/Dockerfile"
repo="zappo"
keys=$HOME/.keys
rhelPid="25590a91-d935-4720-ba5a-3b1756c0add1"
rhelRepo="scan.connect.redhat.com"
gcrRepo=""

latest="${repo}/${name}:latest"
image="${repo}/${name}:${ver}"
rhelImage="${rhelRepo}/ospid-${rhelPid}/${name}:${ver}"
gcrImage="${gcrRepo}/${gcrExt}/${name}:${ver}"

cd ..
docker build -t $latest -f ${dfile} .
docker build -t $image -f ${dfile} .
docker tag $latest $rhelImage
# docker tag $latest $gcrImage

docker push $latest
docker push $image

# bunch of snowflakes
store="{ \"ServerURL\": \"$rhelRepo\", \"Username\": \"unused\", \"Secret\": \"$(cat ${keys}/pidkey-${rhelPid})\"}"
store=$(echo $store | sed -e s/\'/\"/g)
docker-credential-secretservice store <<_EOF
$store
_EOF
docker push $rhelImage
