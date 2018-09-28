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

oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-dev

DB_HOST="mongodb"
DB_USERNAME="mongodb"
DB_PASSWORD="mongodb"
DB_NAME="parks"

oc new-app mongodb-persistent --param MONGODB_DATABASE="${DB_NAME}" --param MONGODB_USER="${DB_USERNAME}" --param MONGODB_PASSWORD="${DB_PASSWORD}" --param MONGODB_ADMIN_PASSWORD="mongodb_admin_password" -n ${GUID}-parks-dev

oc new-app -f ./Infrastructure/templates/mlbparks-dev-template.yaml \
--param DB_HOST=${DB_HOST} \
--param DB_PORT=27017 \
--param DB_USERNAME=${DB_USERNAME} \
--param DB_PASSWORD=${DB_PASSWORD} \
--param DB_NAME=${DB_NAME} \
--param GUID=${GUID} \
-n ${GUID}-parks-dev

oc new-app -f ./Infrastructure/templates/nationalparks-dev-template.yaml \
--param DB_HOST=${DB_HOST} \
--param DB_PORT=27017 \
--param DB_USERNAME=${DB_USERNAME} \
--param DB_PASSWORD=${DB_PASSWORD} \
--param DB_NAME=${DB_NAME} \
--param GUID=${GUID} \
-n ${GUID}-parks-dev

oc new-app -f ./Infrastructure/templates/parksmap-dev-template.yaml --param GUID=${GUID} -n ${GUID}-parks-dev
