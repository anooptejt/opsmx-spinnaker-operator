This is a procedural document to spin up Spinnaker services through OpenShift Operator using Helm Charts

Prerequisites: 

1. oc/kubectl binary and kubeconfig file, user should be having cluster-admin privilege
2. Openshift 3.9 or above


Procedure to deploy the "OpsMx-Spinnaker-Operator": 

1. Start by unzipping  the folder (named as opsmx-spinnaker-operator)

2. Get inside the folder "opsmx-spinnaker-operator" to continue the installation 
       cd opsmx-spinnaker-operator

3. Create a new namespace/project for spinnaker operator to deploy (for example "testoperator"):
       oc create namespace testoperator

4. Check for pre-exisiting CRD of operator:
       oc get crd
   
   Note : If the output of the above command doesn't return the resource "opsmxspinnakeroperators.charts.helm.k8s.io" in the cluster, then please execute the following command :
       oc create -f deploy/crds/charts_v1alpha1_opsmxspinnakeroperator_crd.yaml

5. Create the Service Account for the Operator to deploy "opsmx-spinnaker-operator"
       oc -n testoperator create -f deploy/service_account.yaml 

6. Add the role "opsmx-spinnaker-operator" in the namespace "testoperator"
       oc -n testoperator create -f deploy/role.yaml

7. Add the rolebinding for the Service Account in the namespace "testoperator" 
       oc -n testoperator create -f deploy/role_binding.yaml

8. Now create a deployment "opsmx-spinnaker-operator"  using the below command
       oc -n testoperator create -f deploy/operator.yaml

9. Finally, deploy the charts_v1alpha1_opsmxspinnakeroperator_cr file, which would spin up the deployment, pods, services of the Halyard and Spinnaker.
       oc -n testoperator apply -f deploy/crds/charts_v1alpha1_opsmxspinnakeroperator_cr.yaml 

10. In the next  5-10 min (depending upon the cluster resources), SSnadepinnaker environment  will be up and running
    Please verify it using the command :
       oc -n testoperator get deploy,svc,pods
