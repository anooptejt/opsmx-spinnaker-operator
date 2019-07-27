#!/bin/bash
#
cd ..
docker build -t zappo/spinnaker-operator:latest -f build/Dockerfile .
docker push zappo/spinnaker-operator:latest
