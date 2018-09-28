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

oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=4Gi --param VOLUME_CAPACITY=8Gi -n ${GUID}-jenkins
# Alter resources assigned to pod
oc rollout pause dc jenkins -n ${GUID}-jenkins
oc set resources dc jenkins --requests=memory=2Gi,cpu=1 --limits=memory=6Gi,cpu=1 -n ${GUID}-jenkins
oc rollout resume dc jenkins -n ${GUID}-jenkins

# Push Jenkins slave maven image with skopeo support
#oc process -f ./Infrastructure/templates/maven-slave-template.yaml --param GUID=${GUID} --param CLUSTER=${CLUSTER} | oc create -f - -n ${GUID}-jenkins
oc new-build -D $'FROM docker.io/openshift/jenkins-slave-maven-centos7:v3.9\nUSER root\nRUN yum -y install skopeo && yum clean all\nUSER 1001' --name=jenkins-slave-maven-appdev -n ${GUID}-jenkins

#docker build ./Infrastructure/extra -t docker-registry-default.apps.${CLUSTER}/${GUID}-jenkins/jenkins-slave-maven-appdev:v3.9
#docker login -u $(oc whoami) -p $(oc whoami -t) docker-registry-default.apps.${CLUSTER}
#docker push docker-registry-default.apps.${CLUSTER}/${GUID}-jenkins/jenkins-slave-maven-appdev:v3.9

# Create build config pipelines
oc process -f ./Infrastructure/templates/mlbparks-pipeline-template.yaml --param REPO=${REPO} --param GUID=${GUID} --param CLUSTER=${CLUSTER} | oc create -f - -n ${GUID}-jenkins
oc process -f ./Infrastructure/templates/nationalparks-pipeline-template.yaml --param REPO=${REPO} --param GUID=${GUID} --param CLUSTER=${CLUSTER} | oc create -f - -n ${GUID}-jenkins
oc process -f ./Infrastructure/templates/parksmap-pipeline-template.yaml --param REPO=${REPO} --param GUID=${GUID} --param CLUSTER=${CLUSTER} | oc create -f - -n ${GUID}-jenkins
