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
    -f|--force-crd-delete)
        force=1
        ;;
    -d|--rmi)
        rmi=1
        ;;
    -v|--verbose)
        verbose=1
        ;;
    -n|--namespace)
        shift
        ns=$1
        gaveNs=1
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
crd="openenterprisespinnakeroperators"

usage() {
    echo "Usage: $0 [OPTION...]
  -t|--type=TYPE            Which mini binary to use: minikube, minishift, minispin, crc, none
  -n|--namespace=STRING     The namespace to work one, if none provided the namespace.yml file is used
  -f|--force-crd-delete     Use with caution, may make you unhappy, however sometimes CRDs don't go..
  -d|--rmi                  Remove the docker images
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

if [ -z "$ns" ]; then
    ns=$(cat ./namespace.yaml | jq '.metadata.name' | sed -e s/\"//g)
fi
ncrd=$($kcmd get crds | grep $crd | awk '{ print $1 }')
if [ "$?" == "0" -a "$mini" != "crc" ]; then
    # patch so delete gets easy...
    if [ "$force" == "1" ]; then
        $kcmd delete crds/$ncrd &
        $kcmd patch crds/$ncrd -p '{"metadata":{"finalizers":[]}}' --type=merge
    fi
    $kcmd delete crds/$ncrd

fi
deployments=$($kcmd get deployments -n $ns | grep -v NAME | awk '{ print $1 }')
if [ "$deployments" != "" ]; then
    $kcmd -n $ns delete deployments $deployments
fi
svcs=$($kcmd get svc -n $ns | grep -v NAME | awk '{ print $1 }')
for svc in $svcs; do
    $kcmd -n $ns delete svc $svc
done

# needs to become a var, the spin that is...
secrets=$($kcmd get secrets -n $ns | grep -v NAME | grep Opaque | grep spin | awk '{ print $1}')
for secret in $secrets; do
    $kcmd -n $ns delete secret $secret
done

$kcmd -n $ns delete -f  "../deploy/service_account.yaml"
$kcmd -n $ns delete -f  "../deploy/role.yaml"
$kcmd -n $ns delete -f  "../deploy/role_binding.yaml"
TRUE=true
while $TRUE; do
    count=$($kcmd -n $ns get pods | grep -i NAME | wc -l)
    echo -ne "Waiting for pods to go, $count left\r"
    if [ "$count" == "0" ];then
        echo -ne "\r\nPods are gone, $count left\r\n"
        TRUE=false
    else
        sleep 1
    fi
done

# should check if the operator container can delete the containers for us.... >:)
if [ "$rmi" == "1" ]; then
    echo "Deleting images"
    if [ "$type" == "crc" -o "$type" == "none" ]; then
        echo "Sorry I can't do that Dave: crc does not support access"
    elif [ "$type" != "minispin" -a "$type" != "none" ]; then
        images=$($type ssh "docker images| egrep 'spinnaker-operator|oes' | awk '{ print \$3 }' | tr '\n' ' '")
        for i in $images; do
            echo $type ssh "docker rmi $i --force"
        done
    else
        images=$(sudo docker images| egrep 'spinnaker-operator|oes' | awk '{ print $3 }' | tr '\n' ' ')
        for i in $images; do
            echo sudo docker rmi $i --force
        done
    fi
fi
if [ -e "namespaces.yaml" -a "$gaveNs" != "1" ]; then
    $kcmd -n $ns delete -f ./namespace.yaml
    rm ./namespace.yaml
fi
