#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Nexus in project $GUID-nexus"

# Code to set up the Nexus. It will need to
# * Create Nexus
# * Set the right options for the Nexus Deployment Config
# * Load Nexus with the right repos
# * Configure Nexus as a docker registry

function ocn {
    oc -n $GUID-nexus $@
}

###############
#
# templates
#
###############

ocn create -f Infrastructure/templates/nexus/nexus-data.yml
ocn create -f Infrastructure/templates/nexus/nexus-dc.yml
ocn create -f Infrastructure/templates/nexus/nexus-service.yml
ocn create -f Infrastructure/templates/nexus/nexus-route.yml
ocn create -f Infrastructure/templates/nexus/nexus-registry-service.yml
ocn create -f Infrastructure/templates/nexus/nexus-registry-route.yml

# make sure everything is set up before proceeding
# sleep 10

# Readiness check
NEXUS3_ROUTE=http://$(oc -n $GUID-nexus get route nexus3 --template='{{ .spec.host }}')
until $(curl --output /dev/null --silent --head --fail $NEXUS3_ROUTE/repository/maven-public/); do
    printf '.'
    sleep 1
done

# Nexus setup
curl -o setup_nexus3.sh -s https://raw.githubusercontent.com/wkulhanek/ocp_advanced_development_resources/master/nexus/setup_nexus3.sh
bash setup_nexus3.sh admin admin123 $NEXUS3_ROUTE
rm setup_nexus3.sh

#########################################################################################

###############
#
# oc commands
#
###############


# ocn create -f templates/nexus-data.yml

# ocn new-app sonatype/nexus3:latest
# ocn rollout pause dc nexus3

# ocn patch dc nexus3 --patch='{ "spec": { "strategy": { "type": "Recreate" }}}'
# ocn set resources dc nexus3 --limits=memory=2Gi --requests=memory=1Gi

# ocn expose svc nexus3

# ocn expose dc nexus3 \
#     --port=5000 \
#     --name=nexus-registry \

# ocn create route edge nexus-registry \
#     --service=nexus-registry \
#     --port=5000


# ocn set volume dc/nexus3 \
#     --add \
#     --overwrite \
#     --name=nexus3-volume-1 \
#     --mount-path=/nexus-data/ \
#     --type persistentVolumeClaim \
#     --claim-name=nexus-pvc

# ocn set probe dc/nexus3 \
#     --liveness \
#     --failure-threshold 3 \
#     --initial-delay-seconds 60 \
#     -- echo ok

# ocn set probe dc/nexus3 \
#     --readiness \
#     --failure-threshold 3 \
#     --initial-delay-seconds 60 \
#     --get-url=http://:8081/repository/maven-public/