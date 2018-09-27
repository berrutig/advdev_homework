#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# Code to set up the SonarQube project.
# Ideally just calls a template
# oc new-app -f ../templates/sonarqube.yaml --param .....

# To be Implemented by Student

# alias OC to project namespace
# shopt -s expand_aliases
# ocn="oc -n $GUID-sonarqube"

function ocn {
    oc -n $GUID-sonarqube $@
}

###############
#
# templates
#
###############

# Ignore SonarQube to save resources

# ocn create -f Infrastructure/templates/sonar/sonar-postgres.yml
# ocn create -f Infrastructure/templates/sonar/sonar-data.yml
# ocn create -f Infrastructure/templates/sonar/sonar-dc.yml
# ocn create -f Infrastructure/templates/sonar/sonar-service.yml
# ocn create -f Infrastructure/templates/sonar/sonar-route.yml



# Postgres
# ocn new-app \
#     --template=postgresql-persistent \
#     --param POSTGRESQL_USER=sonar \
#     --param POSTGRESQL_PASSWORD=sonar \
#     --param POSTGRESQL_DATABASE=sonar \
#     --param VOLUME_CAPACITY=4Gi \
#     --labels=app=sonarqube

# ocn create -f templates/sonar/sonar-data.yml

# ocn new-app \
#     --docker-image=wkulhanek/sonarqube:6.7.4 \
#     --env=SONARQUBE_JDBC_USERNAME=sonar \
#     --env=SONARQUBE_JDBC_PASSWORD=sonar \
#     --env=SONARQUBE_JDBC_URL=jdbc:postgresql://postgresql/sonar \
#     --labels=app=sonarqube

# ocn rollout pause dc sonarqube
# ocn expose service sonarqube

# ocn set volume dc/sonarqube \
#     --add \
#     --overwrite \
#     --name=sonarqube-volume-1 \
#     --mount-path=/opt/sonarqube/data/ \
#     --type persistentVolumeClaim \
#     --claim-name=sonarqube-pvc

# ocn set resources dc/sonarqube \
#     --limits=memory=3Gi,cpu=2 \
#     --requests=memory=2Gi,cpu=1

# ocn patch dc sonarqube --patch='{ "spec": { "strategy": { "type": "Recreate" }}}'

# ocn set probe dc/sonarqube \
#     --liveness \
#     --failure-threshold 3 \
#     --initial-delay-seconds 40 -- echo ok

# ocn set probe dc/sonarqube \
#     --readiness \
#     --failure-threshold 3 \
#     --initial-delay-seconds 20 --get-url=http://:9000/about

# ocn rollout resume dc sonarqube
