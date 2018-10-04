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

# Reset mlbparks app
oc delete svc mlbparks-green -n ${GUID}-parks-prod
oc delete svc mlbparks-blue -n ${GUID}-parks-prod
oc expose dc mlbparks-green --port 8080 -l type=parksmap-backend -n ${GUID}-parks-prod
oc expose dc mlbparks-blue --port 8080 -n ${GUID}-parks-prod
mlbparksCurrent=$(oc get route mlbparks -n ${GUID}-parks-prod --template='{{ .spec.to.name}}')
if [ "$mlbparksCurrent" == "mlbparks-blue" ]
then
  oc patch route mlbparks -n ${GUID}-parks-prod -p '{"spec":{"to":{"name":"mlbparks-green"}}}'
else
  echo "mlbparks route not patched because it is already on green target"
fi

# Reset nationalparks app
oc delete svc nationalparks-green -n ${GUID}-parks-prod
oc delete svc nationalparks-blue -n ${GUID}-parks-prod
oc expose dc nationalparks-green --port 8080 -l type=parksmap-backend -n ${GUID}-parks-prod
oc expose dc nationalparks-blue --port 8080 -n ${GUID}-parks-prod
nationalparksCurrent=$(oc get route nationalparks -n ${GUID}-parks-prod --template='{{ .spec.to.name}}')
if [ "$nationalparksCurrent" == "nationalparks-blue" ]
then
  oc patch route nationalparks -n ${GUID}-parks-prod -p '{"spec":{"to":{"name":"nationalparks-green"}}}'
else
  echo "nationalparks route not patched because it is already on green target"
fi

# Reset parksmap app
parksmapCurrent=$(oc get route parksmap -n ${GUID}-parks-prod --template='{{ .spec.to.name}}')
if [ "$parksmapCurrent" == "parksmap-blue" ]
then
  oc patch route parksmap -n ${GUID}-parks-prod -p '{"spec":{"to":{"name":"parksmap-green"}}}'
else
  echo "parksmap route not patched because it is already on green target"
fi
