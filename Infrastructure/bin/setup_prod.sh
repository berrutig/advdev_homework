#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Production Environment in project ${GUID}-parks-prod"

# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# To be Implemented by Student

echo "Adding permissions to Jenkins"
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-prod
oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n $GUID-parks-prod
oc policy add-role-to-user admin system:serviceaccount:gpte-jenkins:jenkins -n $GUID-parks-prod


echo "Creating Mongo DB"
oc new-app -f ./Infrastructure/templates/mongo.yaml -n ${GUID}-parks-prod --env=REPLICAS=3 

echo "Creating mlbparks app green"
oc new-app ${GUID}-parks-prod/mlbparks-green:0.0 --name=mlbparks-green --allow-missing-images=true -n ${GUID}-parks-prod -l type=none
oc set triggers dc/mlbparks-green --remove-all -n ${GUID}-parks-prod

oc set probe dc/mlbparks-green --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-prod
oc set probe dc/mlbparks-green --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-prod
oc expose dc mlbparks-green --port 8080 -n ${GUID}-parks-prod
oc create configmap mlbparks-green-config --from-literal=APPNAME="MLB Parks (Green)" -n ${GUID}-parks-prod
oc set env dc/mlbparks-green --from=configmap/mlbparks-green-config -n ${GUID}-parks-prod
oc set deployment-hook dc/mlbparks-green -n ${GUID}-parks-prod --post -- curl -s /usr/bin/curl http://mlbparks:8080/ws/data/load/ -n ${GUID}-parks-prod
oc rollout cancel dc/mlbparks-green -n $GUID-parks-prod

echo "Creating mlbparks app blue"
oc new-app ${GUID}-parks-prod/mlbparks-blue:0.0 --name=mlbparks-blue --allow-missing-images=true -n ${GUID}-parks-prod -l type=parksmap-backend
oc set triggers dc/mlbparks-blue --remove-all -n ${GUID}-parks-prod
oc set probe dc/mlbparks-blue --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-prod
oc set probe dc/mlbparks-blue --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-prod
oc expose dc mlbparks-blue --port 8080 -n ${GUID}-parks-prod --labels=type="parksmap-backend"
oc create configmap mlbparks-blue-config --from-literal=APPNAME="MLB Parks (Blue)" -n ${GUID}-parks-prod
oc set env dc/mlbparks-blue --from=configmap/mlbparks-blue-config -n ${GUID}-parks-prod
oc rollout cancel dc/mlbparks-blue -n $GUID-parks-prod

echo "Creating nationalparks app green"
oc new-app ${GUID}-parks-prod/nationalparks-green:0.0 --name=nationalparks-green --allow-missing-images=true -n ${GUID}-parks-prod -l type=none
oc set triggers dc/nationalparks-green --remove-all -n ${GUID}-parks-prod
oc set probe dc/nationalparks-green --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-prod
oc set probe dc/nationalparks-green --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-prod
oc expose dc nationalparks-green --port 8080 -n ${GUID}-parks-prod
oc create configmap nationalparks-green-config --from-literal=APPNAME="National Parks (Green)" -n ${GUID}-parks-prod
oc set env dc/nationalparks-green --from=configmap/nationalparks-green-config -n ${GUID}-parks-prod
oc set deployment-hook dc/nationalparks-green -n ${GUID}-parks-prod --post -- curl -s http://nationalparks:8080/ws/data/load/ -n ${GUID}-parks-prod
oc rollout cancel dc/nationalparks-green -n $GUID-parks-prod

echo "Creating nationalparks app blue"
oc new-app ${GUID}-parks-prod/nationalparks-blue:0.0 --name=nationalparks-blue --allow-missing-images=true -n ${GUID}-parks-prod -l type=parksmap-backend
oc set triggers dc/nationalparks-blue --remove-all -n ${GUID}-parks-prod
oc set probe dc/nationalparks-blue --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-prod
oc set probe dc/nationalparks-blue --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-prod
oc expose dc nationalparks-blue  --port 8080 -n ${GUID}-parks-prod
oc create configmap nationalparks-blue-config --from-literal=APPNAME="National Parks (Blue)" -n ${GUID}-parks-prod
oc set env dc/nationalparks-blue --from=configmap/nationalparks-blue-config -n ${GUID}-parks-prod
oc rollout cancel dc/nationalparks-blue -n $GUID-parks-prod

echo "Creating parksmap app green"
oc new-app ${GUID}-parks-prod/parksmap-green:0.0 --name=parksmap-green --allow-missing-images=true -n ${GUID}-parks-prod
oc set triggers dc/parksmap-green --remove-all -n ${GUID}-parks-prod

oc set probe dc/parksmap-green --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-prod
oc set probe dc/parksmap-green --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-prod
oc expose dc parksmap-green --port 8080 -n ${GUID}-parks-prod

oc create configmap parksmap-green-config --from-literal=APPNAME="ParksMap (Green)" -n ${GUID}-parks-prod
oc set env dc/parksmap-green --from=configmap/parksmap-green-config -n ${GUID}-parks-prod
oc rollout cancel dc/parksmap-green -n $GUID-parks-prod

echo "Creating parksmap app blue"
oc new-app ${GUID}-parks-prod/parksmap-blue:0.0 --name=parksmap-blue --allow-missing-images=true -n ${GUID}-parks-prod
oc set triggers dc/parksmap-blue --remove-all -n ${GUID}-parks-prod
oc set probe dc/parksmap-blue --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-prod
oc set probe dc/parksmap-blue --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n ${GUID}-parks-prod
oc expose dc parksmap-blue --port 8080 -n ${GUID}-parks-prod
oc expose svc parksmap-blue -n ${GUID}-parks-prod --name parksmap
oc create configmap parksmap-blue-config --from-literal=APPNAME="ParksMap (Blue)" -n ${GUID}-parks-prod
oc set env dc/parksmap-blue --from=configmap/parksmap-blue-config -n ${GUID}-parks-prod
oc rollout cancel dc/parksmap-blue -n $GUID-parks-prod




