#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student

function ocn {
    oc -n $GUID-jenkins $@
}


ocn new-app jenkins-persistent \
    --param ENABLE_OAUTH=true \
    --param VOLUME_CAPACITY=4Gi

ocn set resources dc/jenkins --limits=cpu=800m,memory=1Gi --requests=memory=1Gi

# cant use ocn function here because the $@ pattern interprets the dockerfile as separate arguments
oc -n $GUID-jenkins new-build --name=jenkins-slave-maven-appdev --dockerfile="$(cat ./Infrastructure/templates/jenkins/Dockerfile)"

ocn create -f Infrastructure/templates/jenkins/pipelines.yml