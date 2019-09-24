#!/bin/bash
#
crd="spinnakeroperator"
ns=$(cat ./namespace.yaml | jq '.metadata.name' | sed -e s/\"//g)
type=$1

if [ "$type" != "minikube" -a "$type" != "minishift" -a "$type" != "minispin" ]; then
  echo "$0: (minikube|minishit|minispin)"
  exit 1
elif [ "$type" == "minikube" ]; then
  kcmd="kubectl"
  mini="minikube"
elif [ "$type" == "minishift" ]; then
  kcmd="oc"
  mini="minishift"
# in minispin, minikube runs under root, required for bare-metal deployment.
elif [ "$type" == "minispin" ]; then
  kcmd="kubectl"
  mini="sudo minikube"
fi

ncrd=$(kubectl get crds | grep $crd | awk '{ print $1 }')
if [ "$?" == "0" ]; then
    # patch so delete gets easy...
    # kubectl delete crds/$ncrd &
    # kubectl patch crds/$ncrd -p '{"metadata":{"finalizers":[]}}' --type=merge
    $kcmd delete crds/$ncrd

fi
deployments=$(kubectl get deployments -n $ns | grep -v NAME | awk '{ print $1 }')
if [ "$deployments" != "" ]; then
    $kcmd -n $ns delete deployments $deployments
fi
svcs=$(kubectl get svc -n $ns | grep -v NAME | awk '{ print $1 }')
for svc in $svcs; do 
    $kcmd -n $ns delete svc $svc
done

$kcmd -n $ns delete -f  "../deploy/service_account.yaml"
$kcmd -n $ns delete -f  "../deploy/role.yaml"
$kcmd -n $ns delete -f  "../deploy/role_binding.yaml"
TRUE=true
while $TRUE; do
  count=$($kcmd -n $ns get pods | grep pod | wc -l)
  if [ "$count" == "0" ];then
    echo "Pods are gone"
    TRUE=false
  fi
  echo "Waiting for pods to go"
  sleep 1
done
if [ "$mini" != "minispin" ]; then
  images=$($type ssh "docker images| grep spinnaker-operator | awk '{ print \$3 }' | tr '\n' ' '")
  for i in $images; do
    echo $type ssh "docker rmi $i --force"
  done
else
  images=$(sudo docker images| grep spinnaker-operator | awk '{ print \$3 }' | tr '\n' ' ')
  for i in $images; do
    echo sudo docker rmi $i --force
  done
fi

