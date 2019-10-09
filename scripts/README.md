
Sample scripts that deploys and cleans Spinnaker on K8s and OpenShift 3 and 4 clusters. This script is generally used when testing, on minikube, minishift, crc, a single node distribution minispin, and on normal clusters.

* deploy.sh steps
1. Deploys the Custom Resource Definition
2. Set up account, role, and role binding for Spinnaker
3. Deploy the HELM (Operator) container
4. Deploy Open Enterprise Spinnaker by pushing Custom Resource manifest
5. Wait for Halyard to run, and start tracking speculative progress
6. Wait till deck is running
7. Configure ingress point depending on type of deployment, and ingress config
8. Get ingress point when Deck is running
9. Check gate is running before exit

Usage: ./deploy.sh [OPTION...]
  -t|--type=TYPE            Which mini binary to use: minikube, minishift, minispin, crc, none
  -V|--version=VERSION      Suported Spinnaker version to deploy, 1.15.1, 1.16.0 (1.16.0)
  -n|--namespace=STRING     Namespace to deploy OES in (spin)   
  -v|--verbose              Does nothing
  -h|--help                 This usage
