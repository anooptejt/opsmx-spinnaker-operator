#!/bin/bash -xe
kubectl create -f ../deploy/crds/charts_v1alpha1_opsmxspinnakeroperator_crd.yaml -n operators
kubectl create -f ../deploy/service_account.yaml -n operators
kubectl create -f ../deploy/role.yaml -n operators
kubectl create -f ../deploy/role_binding.yaml -n operators
kubectl create -f ../deploy/operator.yaml -n operators
# kubectl create -f ../deploy/crds/charts_v1alpha1_opsmxspinnakeroperator_cr.yaml -n operators
kubectl create -f spinnaker.yaml -n operators

TRUE=true
while $TRUE; do
  kubectl -n operators get pods | grep spin-deck
  if [ "$?" == "0" ];then
    echo found spin-deck
    TRUE=false
  fi
  echo "waiting for spin-deck"
  sleep 1
done
kubectl -n operators patch svc spin-deck -p '{"spec":{"type": "NodePort" }}'
IP=$(minikube ip)
HALPOD=$(kubectl -n operators get pods | grep halyard | awk '{ print $1 }')
HALPORT=$(kubectl -n operators get svc/spin-deck | perl -ne 'if (/\d+:(\d+)/) { print $1 }')
for i in ui api; do
  cmd="hal config security $i edit \
    --override-base-url http://$IP:$HALPORT/gate"
  kubectl -n operators exec -ti $HALPOD -- bash -c "$cmd"
done
kubectl -n operators exec -ti $HALPOD -- bash -c "hal deploy apply"

