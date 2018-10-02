#!/bin/bash

./setup_projects.sh sjl slibonat-redhat.com
./setup_sonar.sh sjl
./setup_jenkins.sh sjl https://github.com/slibonati/advdev_homework_template na39.openshift.opentlc.com
./setup_dev.sh sjl
./setup_prod.sh sjl
./setup_nexus.sh sjl

