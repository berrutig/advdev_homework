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
#  ✔  5 Set up placeholder deployment configurations for the three microservices
#  ✔  6 Configure the deployment configurations using the ConfigMaps
#  ?  7 Set deployment hooks to populate the database for the back end services
#  ✔  8 Set up liveness and readiness probes
#  ✔  9 Expose and label the services properly (parksmap-backend)

function ocn {
    oc -n $GUID-parks-dev $@
}

ocn create -f Infrastructure/templates/parks-dev/parks-dev-mongodb.yml
ocn policy add-role-to-user admin system:serviceaccount:${GUID}-jenkins:jenkins 

ocn create -f Infrastructure/templates/parks-dev/parks-dev-mongo-creds.yml
# ocn create -f Infrastructure/templates/parks-dev/parks-dev-mlbparks.yml
# ocn create -f Infrastructure/templates/parks-dev/parks-dev-nationalparks.yml
# ocn create -f Infrastructure/templates/parks-dev/parks-dev-parksmap.yml

# Set up parksmap Dev Application
function establish_app {

    # mlbparks is a WAR file
    if [ $1 = mlbparks ]
    then
        ocn new-build jboss-eap70-openshift:1.7 --name=$1 --strategy=source --binary
    else
        ocn new-build redhat-openjdk18-openshift:1.2 --name=$1 --strategy=source --binary
    fi

    # set backend labels
    if [ $1 = parksmap ]
    then
        ocn new-app $GUID-parks-dev/$1:0.0-0 --name=$1 --allow-missing-imagestream-tags=true
    else
        ocn new-app $GUID-parks-dev/$1:0.0-0 --name=$1 --allow-missing-imagestream-tags=true --labels=type=parksmap-backend
    fi
    ocn set triggers dc/$1 --remove-all
    ocn set probe dc/$1 --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30
    ocn set probe dc/$1 --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30
    ocn expose dc $1 --port 8080
    ocn expose svc $1

    # ocn function won't work here, same as elsewhere due to space in the literal
    oc -n $GUID-parks-dev create configmap $1-config --from-literal="APPNAME=$2 (Dev)"
    ocn set env dc/$1 --from=configmap/$1-config
    ocn set env dc/$1 --from=configmap/mongo-creds
}

establish_app parksmap "ParksMap"
establish_app nationalparks "National Parks"
establish_app mlbparks "MLB Parks"


ocn policy add-role-to-user view --serviceaccount=default
