#!/bin/bash 
#
crd="opsmxspinnakeroperators.charts.helm.k8s.io"
ns="operators"

type=$1
if [ "$type" != "k8s" -a "$type" != "oc" ]; then
  echo "$0: (k8s|oc)"
  exit 1
elif [ "$type" == "k8s" ]; then
  type="minikube"
else
  type="minishift"
fi

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
TRUE=true
while $TRUE; do
  kubectl -n $ns get all | grep halyard
  if [ "$?" != "0" ];then
    echo "Halyard is gone"
    TRUE=false
  fi
  echo "Waiting for halyard to go"
  sleep 1
done
images=$($type ssh "docker images| grep operator | awk '{ print \$3 }' | tr '\n' ' '")
for i in $images; do
  $type ssh "docker rmi $i"
done
