#!/bin/bash -xe
#
crd="opsmxspinnakeroperators.charts.helm.k8s.io"
ns="operators"

kubectl get crds | grep $crd
if [ "$?" == "0" ]; then
    kubectl delete crds/$crd
fi
deployments=$(kubectl get deployments -n $ns | grep -v NAME | awk '{ print $1 }')
if [ "$deployments" != "" ]; then
    kubectl -n operators delete deployments $deployments
fi
svcs=$(kubectl get svc -n $ns | grep -v NAME | awk '{ print $1 }')
for svc in $svcs; do 
    kubectl -n operators delete svc $svc
done

kubectl -n $ns delete -f  "../deploy/service_account.yaml"
kubectl -n $ns delete -f  "../deploy/role.yaml"
kubectl -n $ns delete -f  "../deploy/role_binding.yaml"
