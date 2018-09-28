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

oc project ${GUID}-jenkins
oc policy add-role-to-user edit system:serviceaccount:gpte-jenkins:jenkins -n ${GUID}-jenkins

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
oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi -n ${GUID}-jenkins

oc set resources dc/jenkins --limits=cpu=2 --requests=memory=2Gi,cpu=1 -n ${GUID}-jenkins

oc set probe dc jenkins --readiness --initial-delay-seconds=500

# chmod +x setup_jenkins_docker_init.sh

# Sudo to Root to run docker commands
#sudo ./setup_jenkins_docker_init.sh ${GUID} ${USER} $(oc whoami -t)

# Backup existing registries.conf to /etc/containers/registries.conf.yyyyMMddHHMM
echo "Backup existing registries.conf to /etc/containers/registries.conf.yyyyMMddHHMM"
sudo cp /etc/containers/registries.conf /etc/containers/registries.conf.$(date +%Y%m%d%H%M)
sudo cd /home/${USER}/AnanthRHAdvDevHomework/Infrastructure/bin
sudo command cp -fr /home/${USER}/AnanthRHAdvDevHomework/Infrastructure/bin/registries.conf /etc/containers

sudo systemctl enable docker
sudo systemctl start docker

mkdir -p $HOME/jenkins-slave-appdev
cd  $HOME/jenkins-slave-appdev
sudo chmod 777 $HOME/jenkins-slave-appdev
echo "FROM docker.io/openshift/jenkins-slave-maven-centos7:v3.9
USER root
RUN yum -y install skopeo apb && \
    yum clean all
USER 1001" > Dockerfile

sudo docker build . -t docker-registry-default.apps.${CLUSTER}/${GUID}-jenkins/jenkins-slave-maven-appdev:v3.9

sudo skopeo copy --dest-tls-verify=false --dest-creds=$(oc whoami):$(oc whoami -t) docker-daemon:docker-registry-default.apps.${CLUSTER}/${GUID}-jenkins/jenkins-slave-maven-appdev:v3.9 docker://docker-registry-default.apps.${CLUSTER}/${GUID}-jenkins/jenkins-slave-maven-appdev:v3.9	

cd $HOME
rm -rf $HOME/jenkins-slave-appdev

echo "Setting up Openshift Pipeline for MLBParks application"

echo "apiVersion: v1
items:
- kind: "BuildConfig"
  apiVersion: "v1"
  metadata:
    name: "mlbparks-pipeline"
  spec:
    source:
      type: "Git"
      git:
        uri: ${REPO}
    strategy:
      type: "JenkinsPipeline"
      jenkinsPipelineStrategy:
        env:
        - name: GUID
          value: ${GUID}
        - name: CLUSTER
          value: ${CLUSTER}
        jenkinsfilePath: MLBParks/Jenkinsfile
kind: List
metadata: []" | oc create -f - -n ${GUID}-jenkins

echo ">>>>>> Completed setup up Openshift Pipeline for MLBParks application <<<<<<"

echo "apiVersion: v1
items:
- kind: "BuildConfig"
  apiVersion: "v1"
  metadata:
    name: "nationalparks-pipeline"
  spec:
    source:
      type: "Git"
      git:
        uri: ${REPO}
    strategy:
      type: "JenkinsPipeline"
      jenkinsPipelineStrategy:
        env:
        - name: GUID
          value: ${GUID}
        - name: CLUSTER
          value: ${CLUSTER}
        jenkinsfilePath: Nationalparks/Jenkinsfile
kind: List
metadata: []" | oc create -f - -n ${GUID}-jenkins

echo ">>>>>> Completed setup up Openshift Pipeline for Nationalparks application <<<<<<"

echo "apiVersion: v1
items:
- kind: "BuildConfig"
  apiVersion: "v1"
  metadata:
    name: "parksmap-pipeline"
  spec:
    source:
      type: "Git"
      git:
        uri: ${REPO}
    strategy:
      type: "JenkinsPipeline"
      jenkinsPipelineStrategy:
        env:
        - name: GUID
          value: ${GUID}
        - name: CLUSTER
          value: ${CLUSTER}
        jenkinsfilePath: ParksMap/Jenkinsfile
kind: List
metadata: []" | oc create -f - -n ${GUID}-jenkins

echo ">>>>>> Completed setup up Openshift Pipeline for ParksMap application <<<<<<"
