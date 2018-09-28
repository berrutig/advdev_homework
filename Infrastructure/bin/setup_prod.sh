#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Production Environment in project ${GUID}-parks-prod"

oc project ${GUID}-parks-prod
# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

oc policy add-role-to-group system:image-puller system:serviceaccounts:${GUID}-parks-prod -n ${GUID}-parks-dev
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-prod
oc policy add-role-to-user edit system:serviceaccount:gpte-jenkins:jenkins -n ${GUID}-parks-prod

# To be Implemented by Student

git reset --hard HEAD && git pull origin master
cd $HOME/advdev_homework/Infrastructure/templates

# Replicated MongoDB setup
echo "Creating Headless Service"
oc create -f prod-mongodb-headless-service.yml && \

echo "Creating Regular MongoDB Service" && \
oc create -f prod-mongodb-regular-service.yml && \

echo "Creating Stateful Set for MongoDB" && \
oc create -f prod-mongodb-statefulset.yml && \

oc get pvc && \
echo "StatefulSet MongoDB created Successfully"

oc create configmap prod-mongodb-blue-config-map --from-literal="prod-mongodb-connection.properties=Placeholder" -n ${GUID}-parks-prod \n
oc create configmap prod-mongodb-green-config-map --from-literal="prod-mongodb-connection.properties=Placeholder" -n ${GUID}-parks-prod \n

# Blue Application
oc new-app ${GUID}-parks-dev/mlbparks:0.0 --name=mlbparks-blue -e APPNAME="MLB Parks (Blue)" --allow-missing-imagestream-tags=true
oc new-app ${GUID}-parks-dev/nationalparks:0.0 --name=nationalparks-blue -e APPNAME="National Parks (Blue)" --allow-missing-imagestream-tags=true
oc new-app ${GUID}-parks-dev/parksmap:0.0 --name=parksmap-blue -e APPNAME="ParksMap (Blue)" --allow-missing-imagestream-tags=true

oc set triggers dc/mlbparks-blue --remove-all
oc set triggers dc/nationalparks-blue --remove-all
oc set triggers dc/parksmap-blue --remove-all

oc expose dc/mlbparks-blue --port 8080
oc expose dc/nationalparks-blue --port 8080
oc expose dc/parksmap-blue --port 8080

# oc create configmap mlbparks-blue-config --from-literal="application-db.properties=Placeholder"
# oc create configmap nationalparks-blue-config --from-literal="application-db.properties=Placeholder"
# oc create configmap parksmap-blue-config --from-literal="application-db.properties=Placeholder"

# oc env dc/mlbparks-blue --from=configmap/mlbparks-blue-config
# oc env dc/nationalparks-blue --from=configmap/nationalparks-blue-config
# oc env dc/parksmap-blue --from=configmap/parksmap-blue-config

oc env dc/mlbparks-blue --from=configmap/prod-mongodb-blue-config-map
oc env dc/nationalparks-blue --from=configmap/prod-mongodb-blue-config-map
oc env dc/parksmap-blue --from=configmap/prod-mongodb-blue-config-map

oc expose svc/mlbparks-blue --name mlbparks -n ${GUID}-parks-prod
oc expose svc/nationalparks-blue --name nationalparks -n ${GUID}-parks-prod
oc expose svc/parksmap-blue --name parksmap -n ${GUID}-parks-prod

# Green Application
oc new-app ${GUID}-parks-dev/mlbparks:0.0 --name=mlbparks-green -e APPNAME="MLB Parks (Green)" --allow-missing-imagestream-tags=true
oc new-app ${GUID}-parks-dev/nationalparks:0.0 --name=nationalparks-green -e APPNAME="National Parks (Green)" --allow-missing-imagestream-tags=true
oc new-app ${GUID}-parks-dev/parksmap:0.0 --name=parksmap-green -e APPNAME="ParksMap (Green)" --allow-missing-imagestream-tags=true

oc set triggers dc/mlbparks-green --remove-all
oc set triggers dc/nationalparks-green --remove-all
oc set triggers dc/parksmap-green --remove-all

oc expose dc/mlbparks-green --port 8080
oc expose dc/nationalparks-green --port 8080
oc expose dc/parksmap-green --port 8080

# oc create configmap mlbparks-green-config --from-literal="application-db.properties=Placeholder"
# oc create configmap nationalparks-green-config --from-literal="application-db.properties=Placeholder"
# oc create configmap parksmap-green-config --from-literal="application-db.properties=Placeholder"

# oc env dc/mlbparks-green --from=configmap/mlbparks-green-config
# oc env dc/nationalparks-green --from=configmap/nationalparks-green-config
# oc env dc/parksmap-green --from=configmap/parksmap-green-config
