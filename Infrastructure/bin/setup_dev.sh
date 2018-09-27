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

echo "Adding permissions"
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-dev
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev
oc policy add-role-to-user admin system:serviceaccount:gpte-jenkins:jenkins -n $GUID-parks-dev

echo "Creating Mongo DB"
oc new-app -f ./Infrastructure/templates/mongo.yaml -n ${GUID}-parks-dev

echo "Creating mlbparks app"
oc new-build --binary=true --name=mlbparks --image-stream=jboss-eap70-openshift:1.7 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/mlbparks:latest --name=mlbparks --allow-missing-images -n ${GUID}-parks-dev
oc set triggers dc/mlbparks --remove-all -n ${GUID}-parks-dev
oc set probe dc/mlbparks --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-dev
oc set probe dc/mlbparks --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-dev
oc expose dc mlbparks --port 8080 -n ${GUID}-parks-dev
oc expose svc mlbparks -n ${GUID}-parks-dev --labels=type="parksmap-backend"
oc create configmap mlbparks-config --from-literal=APPNAME="MLB Parks (Dev)" -n ${GUID}-parks-dev
oc set env dc/mlbparks --from=configmap/mlbparks-config -n ${GUID}-parks-dev
oc set deployment-hook dc/mlbparks -n ${GUID}-parks-dev --post -- curl -s http://mlbparks:8080/ws/data/load/ 

echo "Creating nationalparks app"
oc new-build --binary=true --name="nationalparks" --image-stream=redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/nationalparks:latest --name=nationalparks --allow-missing-images -n ${GUID}-parks-dev
oc set triggers dc/nationalparks --remove-all -n ${GUID}-parks-dev
oc set probe dc/nationalparks --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-dev
oc set probe dc/nationalparks --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-dev
oc expose dc nationalparks --port 8080 -n ${GUID}-parks-dev
oc expose svc nationalparks -n ${GUID}-parks-dev --labels=type="parksmap-backend"
oc create configmap nationalparks-config --from-literal=APPNAME="National Parks (Dev)" -n ${GUID}-parks-dev
oc set env dc/nationalparks --from=configmap/nationalparks-config -n ${GUID}-parks-dev
oc set deployment-hook dc/nationalparks -n ${GUID}-parks-dev --post -- curl -s http://nationalparks:8080/ws/data/load/ 

echo "Creating parksmap app"
oc new-build --binary=true --name="parksmap" --image-stream=redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/parksmap:latest --name=parksmap --allow-missing-images -n ${GUID}-parks-dev
oc set triggers dc/parksmap --remove-all -n ${GUID}-parks-dev
oc set probe dc/parksmap --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-dev
oc set probe dc/parksmap --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-dev
oc expose dc parksmap --port 8080 -n ${GUID}-parks-dev
oc expose svc parksmap -n ${GUID}-parks-dev
oc create configmap parksmap-config --from-literal=APPNAME="ParksMap (Dev)" -n ${GUID}-parks-dev
oc set env dc/parksmap --from=configmap/parksmap-config -n ${GUID}-parks-dev





