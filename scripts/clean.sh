#!/bin/bash -x

ns="operators"
kubectl delete crds/opsmxspinnakeroperators.charts.helm.k8s.io
deployment= $(kubectl get deployments -n $ns | grep -v NAME | awk '{ print $1 }')
if [ "$deployments" != "" ]; then
    kubectl -n operators delete deployments $deployments
fi
svcs=$(kubectl get svc -n $ns | grep -v NAME | awk '{ print $1 }')
for svc in $svcs; do 
    kubectl -n operators delete svc $svc
done
