#!/bin/bash
#
#
#
usage() {
  echo "$0: -t type -n namespace -V version -help"
}

while [ "$1" != "" ]; do
  case $1 in
    -t|--type)
       shift
       type=$1
       ;;
    -v|--verbose)
       verbose=1
       ;;
    -n|--namespace)
       shift
       ns=$1
       ;;
    -V|--version)
       shift
       version=$1
       ;;
    -h|--help)
       usage
       exit
       ;;
    *)
       usage
       exit 1
    esac
    shift
done
ns=${ns:-spin}
version=${version:-1.16.0}

if [ "$type" != "minikube" -a "$type" != "minishift" -a "$type" != "minispin" ]; then
  echo "$0: (minikube|minishit|minispin)"
  exit 1
elif [ "$type" == "minikube" ]; then
  type="kubectl"
  mini="minikube"
elif [ "$type" == "minishift" ]; then
  type="oc"
  mini="minishift"
# in minispin, minikube runs under root, required for bare-metal deployment.
elif [ "$type" == "minispin" ]; then
  type="kubectl"
  mini="sudo minikube"
fi

cat <<EOF > ../deploy/namespace.yaml
{ "apiVersion": "v1", "kind": "Namespace", "metadata": { "name": "$ns", "labels": { "name": "$ns"} } }
EOF
$type create -f ./namespace.yaml

$type create -f ../deploy/crds/open-enterprise-spinnaker_crd.yaml
$type create -f ../deploy/service_account.yaml -n $ns
$type create -f ../deploy/role.yaml -n $ns
$type create -f ../deploy/role_binding.yaml -n $ns
$type create -f ../deploy/operator.yaml -n $ns
$type create -f ../deploy/crds/deploy-oes.yaml -n $ns

TRUE=true
while $TRUE; do
  kubectl -n $ns get pods | grep spin-deck
  if [ "$?" == "0" ];then
    echo found spin-deck
    TRUE=false
  fi
  halpod=$(kubectl -n $ns get pods | grep halyard | awk '{ print $1 }')
  if [ "$halpod" != "" ]; then
    logcount=$( kubectl logs -n $ns $halpod | wc -l)
    # count is about 5900... for spin-deck to show
    echo -n "halyard progress: $(($logcount / 59))% - "
    res=$(kubectl -n $ns get pods | grep spin-deck)
    if [ "$?" == "0" ]; then
      echo "found $res"
      TRUE=false
    else
      echo "waiting for spin-deck"
    fi
  else
    echo "waiting for halyard"
  fi
  sleep 1
done
IP=$($mini ip)
HALPOD=$(kubectl -n $ns get pods | grep halyard | awk '{ print $1 }')
ingress=$(egrep "ingress:|ingressGate:" ../deploy/crds/deploy-oes.yaml | wc -l)
if [ "$ingress" != "2" ]; then
    echo "No ingress configured, configuring direct connection"
    kubectl -n $ns patch svc spin-deck -p '{"spec":{"type": "NodePort" }}'
    HALPORT=$(kubectl -n $ns get svc/spin-deck | perl -ne 'if (/\d+:(\d+)/) { print $1 }')
    for i in ui api; do
        cmd="hal config security $i edit \
            --override-base-url http://$IP:$HALPORT/gate"
        kubectl -n $ns exec -ti $HALPOD -- bash -c "$cmd"
    done
    kubectl -n $ns exec -ti $HALPOD -- bash -c "hal deploy apply"
    NodePort=$(kubectl get svc/spin-deck -n $ns -o yaml | grep nodePort | awk '{ print $3 }')
else
    echo "Ingress configured"
    NodePort="80"
    ingressHostName=$(grep host: ../deploy/crds/deploy-oes.yaml  | head -1 | awk '{ print $2 }')
    curlopts="-H $ingressHostName "
fi

# check this url, gives 500 till done
TRUE=true
curlopts+="--connect-timeout 2 \
   --max-time 30 \
   --retry 10 \
   --retry-delay 2 \
   --retry-max-time 5"
while $TRUE; do
  res=$(curl $curlopts http://$IP:$NodePort/gate/projects)
  if [ "$?" == "0" ]; then
    echo $res | egrep "500|404"
    if [ "$?" == "1" ]; then
      TRUE=false
    fi
  fi
  sleep 1
done
echo "Deck is running on http://$IP:$NodePort/"
