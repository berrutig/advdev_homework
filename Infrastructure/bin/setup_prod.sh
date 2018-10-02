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


# Jenkins Service Account
oc new-app -f ./Infrastructure/templates/sjl-jenkins-sa.yaml -n 89a4-parks-prod

# Grant the correct permissions to pull images from the development project
# in yaml, but unreliable
oc policy add-role-to-group system:image-puller system:serviceaccounts:89a4-parks-prod -n 89a4-parks-dev

# StatefulSet
oc new-app -f ./Infrastructure/templates/sjl-parks-prod.yaml -n 89a4-parks-prod
# Microservices
oc new-app -f ./Infrastructure/templates/sjl-mlbparks-prod.yaml -n 89a4-parks-prod
oc new-app -f ./Infrastructure/templates/sjl-nationalparks-prod.yaml -n 89a4-parks-prod
oc new-app -f ./Infrastructure/templates/sjl-parksmap-prod.yaml -n 89a4-parks-prod


