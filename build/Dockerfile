FROM quay.io/operator-framework/helm-operator:v0.10.0

LABEL name='open-enterprise-spinnaker'
LABEL vendor='OpsMx'
LABEL release='1'
LABEL version='1.16.0'
LABEL summary='Red Hat certified Operator for deploying Red Hat certified Open Enterprise Spinnaker'
LABEL description='Open Enterprise Spinnaker is an Enterprise grade, Red Hat certified and OpsMx supported release of the popular and critically acclaimed Continuous Delivery platform Spinnaker'
LABEL maintainer='delivery-engineering@opsmx.io'

COPY helm-charts/ ${HOME}/helm-charts/
COPY build/watches.yaml ${HOME}/watches.yaml
COPY build/licenses /licenses
