#!/bin/bash
#
cd ..
image_name="spinnaker-operator"
tag="1.15.1-4"
combo="${image_name}:${tag}"
ospid="25590a91-d935-4720-ba5a-3b1756c0add1"
scan="scan.connect.redhat.com"
remote="${scan}/ospid-${ospid}/${combo}"
pidkey="${HOME}/.keys/pidkey-${ospid}"
PIDKEY=$(cat ${pidkey})

: "${PIDKEY?require export \$PIDKEY, or $pidkey for ospid $ospid at $scan}"

echo $PIDKEY | docker login -u unused ${scan}  --password-stdin=true
docker build -t cert/cert-${combo} -f build/Dockerfile .
did=$(docker images | grep cert-${image_name} | head -1 | awk '{ print $3 }')
docker tag $did $remote
docker push $remote
docker logout $scan
