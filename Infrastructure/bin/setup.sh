#!/bin/bash

./setup_projects.sh 89a4 dusan.culibrk-devoteam.com
./setup_sonar.sh 89a4
./setup_jenkins.sh 89a4 https://github.com/dulecux/advdev_homework na39.openshift.opentlc.com
./setup_dev.sh 89a4
./setup_prod.sh 89a4
./setup_nexus.sh 89a4

