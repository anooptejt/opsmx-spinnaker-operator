#!/bin/bash
#
cd ..
docker build -t zappo/spinnaker-operator:latest -f build/Dockerfile .
docker build -t zappo/spinnaker-operator:1.15.1-5 -f build/Dockerfile .
docker push zappo/spinnaker-operator:latest
docker push zappo/spinnaker-operator:1.15.1-5
