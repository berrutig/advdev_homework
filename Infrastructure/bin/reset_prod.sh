#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Resetting Parks Production Environment in project ${GUID}-parks-prod to Green Services"

# Code to reset the parks production environment to make
# all the green services/routes active.
# This script will be called in the grading pipeline
# if the pipeline is executed without setting
# up the whole infrastructure to guarantee a Blue
# rollout followed by a Green rollout.

# To be Implemented by Student
function ocn {
    oc -n $GUID-parks-prod $@
}

function reset_app {
    if [ $1 != parksmap ]
    then
        ocn label svc $1-blue type-
        ocn label svc $1-green type=parksmap-backend --overwrite
    fi
    ocn set route-backends $1 $1-green=1 $1-blue=0
}

reset_app mlbparks
reset_app nationalparks
reset_app parksmap