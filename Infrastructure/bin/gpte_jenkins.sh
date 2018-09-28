#!/bin/bash
# Create all Homework Projects
if [ "$#" -ne 2 ]; then
    echo "Usage:"
    echo "  $0 GUID USER"
    exit 1
fi

GUID=$1
USER=$2
echo "Creating all Homework Projects for GUID=${GUID} and USER=${USER}"
oc login https://master.na39.openshift.opentlc.com -u ${USER} -p securityPolicy@1234

oc new-project grading-jenkins --display-name="My Homework Grading Jenkins"

oc project grading-jenkins

oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi -n grading-jenkins
oc set resources dc/jenkins --limits=cpu=1,memory=3Gi --requests=memory=2Gi,cpu=1 -n grading-jenkins

oc create clusterrole namespace-patcher --verb=patch --resource=namespaces
oc adm policy add-cluster-role-to-user namespace-patcher system:serviceaccount:grading-jenkins:jenkins
oc adm policy add-cluster-role-to-user self-provisioner system:serviceaccount:grading-jenkins:jenkins

oc policy add-role-to-user edit system:serviceaccount:grading-jenkins:default -n grading-jenkins
oc run restartjenkins --schedule="0 23 * * *" --restart=OnFailure -n grading-jenkins --image=registry.access.redhat.com/openshift3/jenkins-2-rhel7:v3.9 -- /bin/sh -c "oc scale dc jenkins --replicas=0 && sleep 20 && oc scale dc jenkins --replicas=1"
