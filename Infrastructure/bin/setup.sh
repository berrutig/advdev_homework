#!/bin/bash

./setup_projects.sh sjl dusan.culibrk-devoteam.com
./setup_sonar.sh sjl
./setup_jenkins.sh sjl https://github.com/dulecux/advdev_homework na39.openshift.opentlc.com
./setup_dev.sh sjl
./setup_prod.sh sjl
./setup_nexus.sh sjl

