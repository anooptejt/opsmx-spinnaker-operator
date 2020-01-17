#!/bin/bash
#
#
#
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
        $0
        exit
        ;;
    *)
        $0
        exit 1
    esac
    shift
done
ns=${ns:-spin}
version=${version:-1.17.4}

usage() {
  echo "Usage: $0 [OPTION...]
  -t|--type=TYPE            Which mini binary to use: minikube, minishift, minispin, crc, k8s, openshift (no default)
  -V|--version=VERSION      Suported Spinnaker version to deploy, 1.15.1, $version ($version)
  -n|--namespace=STRING     Namespace to deploy OES in ($ns)
  -v|--verbose              Does nothing
  -h|--help                 This usage
"
}

if [ "$type" != "minikube" -a "$type" != "minishift" -a "$type" != "minispin" -a "$type" != "k8s" -a "$type" != "openshift" -a "$type" != "crc" ]; then
    usage
    exit 1
elif [ "$type" == "minikube" ]; then
    kcmd="kubectl"
    mini="minikube"
elif [ "$type" == "minishift" -o "$type" == "crc" ]; then
    kcmd="oc"
    mini=$type
# in minispin, minikube runs under root, required for bare-metal deployment.
elif [ "$type" == "minispin" ]; then
    kcmd="kubectl"
    mini="sudo minikube"
elif [ "$type" == "kubectl" -o "$type" == "oc" ]; then
    kcmd=$type
    mini=""
fi

cat <<EOF > ./namespace.yaml
{ "apiVersion": "v1", "kind": "Namespace", "metadata": { "name": "$ns", "labels": { "name": "$ns"} } }
EOF
$kcmd create -f ./namespace.yaml

$kcmd create -f ../deploy/crds/open-enterprise-spinnaker_crd.yaml
$kcmd create -f ../deploy/service_account.yaml -n $ns
$kcmd create -f ../deploy/role.yaml -n $ns
$kcmd create -f ../deploy/role_binding.yaml -n $ns
$kcmd create -f ../deploy/operator.yaml -n $ns
deployFile="../deploy/crds/deploy-oes-${version}.yaml"
if [ -f "$deployFile" ]; then
    echo "Deploying $version"
    $kcmd create -f $deployFile -n $ns
else
    echo "Deploying default"
    deployFile="../deploy/crds/deploy-oes.yaml"
    $kcmd create -f $deployFile -n $ns
fi


TRUE=true
while $TRUE; do
    $kcmd -n $ns get pods | grep spin-deck
    if [ "$?" == "0" ]; then
        echo "Found spin-deck"
        TRUE=false
    fi
    halpod=$($kcmd -n $ns get pods | grep halyard | awk '{ print $1 }')
    if [ "$halpod" != "" ]; then
        logcount=$( kubectl logs -n $ns $halpod | wc -l)
        # count is about 5900... for spin-deck to show
        pct=$(($logcount / 59))
        echo -n "Halyard progress: ${pct}% - "
        res=$($kcmd -n $ns get pods | grep spin-deck)
        if [ "$?" == "0" ]; then
            echo -ne "\r\nfound $res\r\n"
            TRUE=false
        else
            echo -ne "waiting for spin-deck\r"
            sleep 1
        fi
    else
        echo -ne "waiting for halyard\r"
        sleep 1
    fi
done

HALPOD=$($kcmd -n $ns get pods | grep halyard | awk '{ print $1 }')
ingress=$(egrep "ingress:|ingressGate:" $deployFile | wc -l)

if [ "$mini" != "" ]; then
    IP=$($mini ip)
else
    IP=""
fi

if [ "$ingress" != "2" -a "$IP" != "" ]; then
    echo "No ingress configured, configuring direct connection"
    $kcmd -n $ns patch svc spin-deck -p '{"spec":{"type": "NodePort" }}'
    HALPORT=$($kcmd -n $ns get svc/spin-deck | perl -ne 'if (/\d+:(\d+)/) { print $1 }')
    for i in ui api; do
        cmd="hal config security $i edit \
            --override-base-url http://$IP:$HALPORT/gate"
        $kcmd -n $ns exec -ti $HALPOD -- bash -c "$cmd"
    done
    $kcmd -n $ns exec -ti $HALPOD -- bash -c "hal deploy apply"
    NodePort=$($kcmd get svc/spin-deck -n $ns -o yaml | grep nodePort | awk '{ print $3 }')
    LISTENER=$IP:$NodePort
elif [ "$ingress" == "2" ]; then
    echo "Ingress configured"
    NodePort="80"
    ingressHostName=$(grep host: $deployFile  | head -1 | awk '{ print $2 }')
    curlopts="-H $ingressHostName "
    LISTENER=$ingressHostName
else
    echo "No ingress, or IP defined, please use the kubectl tunnel forward method"
    exit 0
fi

# check this url, gives 500 till done
TRUE=true
curlopts+="--connect-timeout 2 \
    --max-time 30 \
    --retry 10 \
    --retry-delay 2 \
    --retry-max-time 5"
SECONDS=0

if [ "$ingressHostName" != "$LISTENER" ];then 
    echo probing $ingressHostName on http://$LISTENER/gate/projects
    while $TRUE; do
        delta=$SECONDS
        echo -ne "Waiting for gate to respond: ${delta}s\r"
        res=$(curl -s $curlopts http://$LISTENER/gate/projects)
        if [ "$?" == "0" ]; then
            echo $res | egrep "500|404"
            if [ "$?" == "1" ]; then
                TRUE=false
           fi
       fi
       sleep 1
    done
fi
echo "Deck is running on http://$LISTENER/"
