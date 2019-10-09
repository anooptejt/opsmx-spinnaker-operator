
Below are sample scripts that deploy and clean Red Hat Certified [Spinnaker](https://www.spinnaker.io/) Containers on K8s and OpenShift 3 and 4 clusters. The deploy.sh script is generally used when testing, on [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/), [minishift](https://www.okd.io/minishift/), [crc](https://code-ready.github.io/crc/), but can be used on any distribution of K8s. The clean.sh script is used to clean up the deployment. Contrary to the OpenShift MarketPlace Operator the clean.sh scripts removes every trace of the CRD and the Spinnaker deployment. By default, when using the OpenShift MarketPlace Operator, and removing the Operator, only the Operator gets removed. The deployed Spinnaker install is left alone.

# Configuration
Configuration is done by editing the manifest files. The deploy.sh script uses deploy/crds/deploy-oes.yaml. The configuration options that are valid are listed in the deploy/crds/open-enterprise-spinnaker_cr.yaml

## an ingress example
Changing the ingress can be done as so, make sure the DNS names resolve.
```
ingress:
  enabled: true
  host: spinnaker.example.org
  annotations:
    ingress.kubernetes.io/ssl-redirect: 'false'
    kubernetes.io/ingress.class: nginx
  #  kubernetes.io/tls-acme: "true"
  # tls:
  # - secretName: -tls
  #    hosts:
  #      - domain.com

ingressGate:
  enabled: true
  host: gate.spinnaker.example.org
  annotations:
    ingress.kubernetes.io/ssl-redirect: 'false'
    kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
```
## changing versions
The Halyad container, and deployed spinnaker version, are controlled with the following variables. Where the spinnakerVersion has to match a supported HELM chart for now, and later a supported BOM. The defaults in the configuration file is the last "known good" supported.
```
spec:
  halyard:
    spinnakerVersion: 1.15.1
    image:
      repository: devopsmx/ubi8-oes-operator-halyard
      tag: 1.15.1-1
```
# deploy.sh steps
1. Deploys the Custom Resource Definition
2. Set up account, role, and role binding for Spinnaker
3. Deploy the HELM (Operator) container
4. Deploy Open Enterprise Spinnaker by pushing Custom Resource manifest
5. Wait for Halyard to run, and start tracking speculative progress
6. Wait till deck is running
7. Configure ingress point depending on deployment type, and ingress configuration in deploy/crds/deploy-oes.yaml
8. Get ingress point when Deck is running
9. Check gate is running before exit

Usage: ./deploy.sh [OPTION...]
  -t|--type=TYPE            Which mini binary to use: minikube, minishift, minispin, crc, k8s, openshift (no default)
  -V|--version=VERSION      Suported Spinnaker version to deploy, 1.15.1, 1.16.0 (1.15.1)
  -n|--namespace=STRING     Namespace to deploy OES in (spin)   
  -v|--verbose              Does nothing
  -h|--help                 This usage

e.g., ./deploy.sh -t kubectl

# clean.sh steps
1. Delete the Custom Resource Definition, when forced patch it to remove finalizers (cough)
2. Delete the Deployments
3. Delete the Services
4. Delete the account, role, and role binding for Spinnaker
5. Wait till all the pods are gone
6. Depending on type of deployment, and flag delete container images

Usage: ./clean.sh [OPTION...]
  -t|--type=TYPE            Which mini binary to use: minikube, minishift, minispin, crc, none
  -f|--force-crd-delete     Use with caution, may make you unhappy, however sometimes CRDs don't go..
  -d|--rmi                  Remove the docker images
  -v|--verbose              Does nothing
  -h|--help                 This usage

e.g., ./clean.sh -t kubectl
