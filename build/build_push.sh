#!/bin/bash
#
# Builds the spinnaker operator and pushes it to selected repos
#
name="spinnaker-operator"
ver="1.16.0-1"
dfile="build/Dockerfile"
keys=$HOME/.keys
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
gcrUser="opsmxadmn@gmail.com"
gcrCredsFile="${keys}/gcr.auth"

pushRemote() {
  repo=$1
  user=$2
  credsFile=$3
  image=$4

  cat $credsFile | docker login --username $user --password-stdin $repo
  docker push $image
}

cd ..
docker build -t $latest -f ${dfile} .
docker build -t $image -f ${dfile} .
docker tag $latest $rhImage
# docker tag $latest $gcrImage

pushRemote $dockerReg $dockerUser $dockerCredsFile $image
pushRemote $dockerReg $dockerUser $dockerCredsFile $latest
# pushRemote $rhReg $rhUser $rhCredsFile $rhImage
# pushRemote $gcrRepo $gcrUser $gcrCredsFile $gcrImage
