This directory contains the Dockerfile, and a push script for the Operator Container

# build_push.sh
Builds the container and pushes it to its specific Red Hat and Docker registry.

Usage: ./build_push [OPTION...]
-o|--operator-name=STRING Name of the operator container
-k|--keys-location=STRING Location of the keys
-r|--push-redhat          Push to the Red Hat registry
-d|--push-docker          Push to the Docker registry
-V|--version=VERSION      Version to tag the image with
-v|--verbose              Does nothing
-h|--help                 This usage
e.g., ./build_push -o spinnaker-operator -k $HOME/.keys -r -p -V 1.16.0-1
