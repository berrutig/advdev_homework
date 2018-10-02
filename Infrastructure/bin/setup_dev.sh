#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student

# Create MongoDB db
oc get -o=yaml template mongodb-persistent -n openshift | oc process -f - -p MONGODB_USER=mongodb -p MONGODB_PASSWORD=mongodb -p MONGODB_DATABASE=parks -p MONGODB_ADMIN_PASSWORD=mongodb -p VOLUME_CAPACITY=2Gi | oc create -f - -n ${GUID}-parks-dev
# Jenkins Service Account
oc new-app -f ./Infrastructure/templates/sjl-jenkins-sa.yaml -n 89a4-parks-dev
# Microservices
oc new-app -f ./Infrastructure/templates/sjl-mlbparks-dev.yaml -n 89a4-parks-dev
oc new-app -f ./Infrastructure/templates/sjl-nationalparks-dev.yaml -n 89a4-parks-dev
oc new-app -f ./Infrastructure/templates/sjl-parksmap-dev.yaml -n 89a4-parks-dev
