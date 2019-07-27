#!/bin/bash -x

ns="operators"
grep="awk '{ print \$1 }' | grep -v NAME"
kubectl delete crds/opsmxspinnakeroperators.charts.helm.k8s.io
kubectl -n operators delete deployments \
    $(kubectl get deployments -n $ns | $grep)
svcs=$(kubectl get svc -n $ns | $grep)
for svc in $svcs; do 
    kubectl -n operators delete svc $svc & 
done
