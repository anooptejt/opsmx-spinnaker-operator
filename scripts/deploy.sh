#!/bin/bash 
#
# 
#
type=$1
if [ "$type" != "k8s" -a "$type" != "oc" ]; then
  echo "$0: (k8s|oc)"
  exit 1
elif [ "$type" == "k8s" ]; then
  type="kubectl"
  mini="minikube"
else
  type="oc"
  mini="minishift"
fi
ns=${2:-spin}

cat <<EOF > ../deploy/namespace.yaml
{ "apiVersion": "v1", "kind": "Namespace", "metadata": { "name": "$ns", "labels": { "name": "$ns"} } }
EOF
$type create -f ../deploy/namespace.yaml

$type create -f ../bundle/open-enterprise-spinnaker_crd.yaml
$type create -f ../deploy/service_account.yaml -n $ns
$type create -f ../deploy/role.yaml -n $ns
$type create -f ../deploy/role_binding.yaml -n $ns
$type create -f ../deploy/deploy-operator.yaml -n $ns
$type create -f ../deploy/deploy-oes.yaml -n $ns

TRUE=true
while $TRUE; do
  kubectl -n $ns get pods | grep spin-deck
  if [ "$?" == "0" ];then
    echo found spin-deck
    TRUE=false
  fi
  echo "waiting for spin-deck"
  sleep 1
done
kubectl -n $ns patch svc spin-deck -p '{"spec":{"type": "NodePort" }}'
IP=$($mini ip)
HALPOD=$(kubectl -n $ns get pods | grep halyard | awk '{ print $1 }')
HALPORT=$(kubectl -n $ns get svc/spin-deck | perl -ne 'if (/\d+:(\d+)/) { print $1 }')
for i in ui api; do
  cmd="hal config security $i edit \
    --override-base-url http://$IP:$HALPORT/gate"
  kubectl -n $ns exec -ti $HALPOD -- bash -c "$cmd"
done
kubectl -n $ns exec -ti $HALPOD -- bash -c "hal deploy apply"
NodePort=$(kubectl get svc/spin-deck -n $ns -o yaml | grep nodePor | awk '{ print $3 }')

# check this url, gives 500 till done
TRUE=true
while $TRUE; do
  curl http://$IP:$NodePort/gate/projects | grep 500
  if [ "$?" == "1" ]; then
    TRUE=false
  fi
done
echo "Deck is running on http://$IP:$NodePort/"
