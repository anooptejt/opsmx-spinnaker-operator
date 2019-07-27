kubectl delete crds/spinnakeroperators.charts.helm.k8s.io
kubectl -n operators delete deployments `kubectl get deployments -n operators | awk '{ print $1 }' | grep -v NAME`
for i in `kubectl get svc -n operators | awk '{ print $1 }' | grep -v NAME`;do kubectl -n operators delete svc $i & done
