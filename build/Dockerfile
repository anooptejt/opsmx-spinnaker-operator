FROM quay.io/operator-framework/helm-operator:v0.10.0

LABEL name='spinnaker-operator'
LABEL vendor='OpsMx'
LABEL release='1.15.1-3'
LABEL version='1.15.1-1'
LABEL summary='Red Hat certified Open Enterprise Operator for deploying Spinnaker'
LABEL description='Certified Open Enterprise Spinnaker is an Enterprise grade, Red Hat certified and OpsMx supported release of the popular and critically acclaimed Continuous Delivery platform Spinnaker'
LABEL maintainer='delivery-engineering@opsmx.io'

COPY helm-charts/ ${HOME}/helm-charts/
COPY watches.yaml ${HOME}/watches.yaml
COPY licenses /licenses
