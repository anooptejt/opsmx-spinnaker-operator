#!/bin/bash -xe
kubectl create -f ../deploy/crds/charts_v1alpha1_opsmxspinnakeroperator_crd.yaml -n operators
kubectl create -f ../deploy/service_account.yaml -n operators
kubectl create -f ../deploy/role.yaml -n operators
kubectl create -f ../deploy/role_binding.yaml -n operators
kubectl create -f ../deploy/operator.yaml -n operators
# kubectl create -f ../deploy/crds/charts_v1alpha1_opsmxspinnakeroperator_cr.yaml -n operators
kubectl create -f spinnaker.yaml -n operators
