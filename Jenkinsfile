#!groovy

// Run this pipeline on the custom Maven Slave ('maven-appdev')
// Maven Slaves have JDK and Maven already installed
// 'maven-appdev' has skopeo installed as well.

// Globals
def GUID = "89a4"
def customSlavePod = "maven-appdev"
def customSlaveContainer = "docker-registry.default.svc:5000/${GUID}-jenkins/jenkins-slave-maven-appdev"
def token = "aOJPhBGzCuN-pW4fpnZ6FOEB6m1PM7CJqtDKs67Yegw"      // FIXME: set valid token
def mvnCmd = "mvn -s ./nexus_openshift_settings.xml"           // TODO: make sure the settings.xml is in the repo

// Custom pod template using container with added Skopeo
podTemplate(label: customSlavePod
          , serviceAccount: 'jenkins'
          , cloud: 'openshift'
          , containers: [containerTemplate(
                          name: 'jnlp'
                        , image: customSlaveContainer
                        , workingDir: "/tmp"
                        , command: ''
                        , alwaysPullImage: false
                        , ttyEnabled: false
                        , args: '${computer.jnlpmac} ${computer.name}'
                        , resourceLimitCpu: '1000m'
                        , resourceLimitMemory: '2Gi'
                        , resourceRequestMemory: '1Gi')]
              ){
  node(customSlavePod) {
          // Checkout Source Code
          stage('Checkout Source') {
              echo "Checking out source"
              checkout([
                    $class: 'GitSCM'
                  , branches: [[name: '*/master']]
                  , doGenerateSubmoduleConfigurations: false
                  , extensions: []
                  , submoduleCfg: []
                  , userRemoteConfigs: [[
                          credentialsId: 'e63cbb60-a828-4752-bdd4-e23579eb6eca'
                        , url: 'http://gogs-mrc-gogs.apps.muc.example.opentlc.com/CICDLabs/openshift-tasks-private.git'
                        ]] // FIXME: change URL
                  ])
          }

          // Extract version and other properties from the pom.xml
          def groupId    = getGroupIdFromPom("pom.xml")
          def artifactId = getArtifactIdFromPom("pom.xml")
          def version    = getVersionFromPom("pom.xml")

          // Set the tag for the development image: version + build number
          def devTag  = version + env.BUILD_ID
          // Set the tag for the production image: version
          def prodTag = version

          def masterURL = 'https://master.na39.openshift.opentlc.com'

          // Using Maven build the war file
          // Do not run tests in this step
          stage('Build war') {
            echo "Building version ${version}"
            // sh "${mvnCmd} -DskipTests install"
          }

          // Using Maven run the unit tests
          stage('Unit Tests') {
            echo "Running Unit Tests"
        //     sh "${mvnCmd} test"
          }

          // Using Maven call SonarQube for Code Analysis
          stage('Code Analysis') {
            echo "Running Code Analysis"
            // sh "${mvnCmd} sonar:sonar -Dsonar.host.url=http://sonarqube-mrc-sonarqube.apps.muc.example.opentlc.com"
          }

          // Publish the built war file to Nexus
          stage('Publish to Nexus') {
            echo "Publish to Nexus"
            // sh "${mvnCmd} deploy deploy -DskipTests=true -DaltDeploymentRepository=nexus::default::http://nexus3-mrc-nexus.apps.muc.example.opentlc.com/repository/releases"
          }

          // Build the OpenShift Image in OpenShift and tag it.
          stage('Build and Tag OpenShift Image') {
            echo "Building OpenShift container image tasks:${devTag}"
            // start build
            openshiftBuild apiURL: masterURL
                  , authToken: token
                  , bldCfg: 'tasks'
                  , checkForTriggeredDeployments: 'false'
                  , namespace: 'mrc-tasks-dev'
                  , showBuildLogs: 'true'//, waitTime: '', waitUnit: 'sec'
            
            openshiftTag apiURL: masterURL
                  , alias: 'false'
                  , authToken: token
                  , destStream: 'tasks'
                  , destTag: "${devTag}"
                  , destinationAuthToken: ''
                  , destinationNamespace: 'mrc-tasks-dev'
                  , namespace: 'mrc-tasks-dev'
                  , srcStream: 'tasks'
                  , srcTag: 'latest'
                  , verbose: 'false'
          }

          // Deploy the built image to the Development Environment.
          stage('Deploy to Dev') {
            echo "Deploying container image to Development Project"
            sh "oc set image dc/tasks tasks=docker-registry.default.svc:5000/mrc-tasks-dev/tasks:${devTag} -n mrc-tasks-dev"

            // remove all volume mounts && delete existing configmap
            sh "oc volume dc --remove --all --confirm -n mrc-tasks-dev"
            sh "oc delete configmap --all -n mrc-tasks-dev"
            
            // create new configmap...
            sh "oc create configmap jboss-files --from-file=./configuration/application-users.properties --from-file=./configuration/application-roles.properties -n mrc-tasks-dev"
            
            // ...then mount it
            sh "oc volume dc/tasks --add -t=configmap --configmap-name=jboss-files --name=jboss-roles-mount -m=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties -n mrc-tasks-dev"
            sh "oc volume dc/tasks --add -t=configmap --configmap-name=jboss-files --name=jboss-users-mount -m=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties -n mrc-tasks-dev"
            
            openshiftDeploy apiURL: masterURL
                  , authToken: token
                  , depCfg: 'tasks'
                  , namespace: 'mrc-tasks-dev'

            openshiftVerifyDeployment apiURL: masterURL
                  , authToken: token
                  , depCfg: 'tasks'
                  , namespace: 'mrc-tasks-dev'
                  , replicaCount: '1'
                  , verbose: 'false'
                  , verifyReplicaCount: 'true'

            openshiftVerifyService apiURL: masterURL
                  , authToken: token
                  , namespace: 'mrc-tasks-dev'
                  , svcName: 'tasks'
                  , verbose: 'false'
          }

        // sh " -n mrc-tasks-dev"

          // Run Integration Tests in the Development Environment.
          stage('Integration Tests') {
            // sleep 50

            // def route = "http://tasks-mrc-tasks-dev.apps.muc.example.opentlc.com"
            // echo "Running Integration Tests"
            
            // sh "curl -u tasks:redhat1 -H 'Content-Length: 0' -X POST ${route}/ws/tasks/my-task"
            
            // echo "set variables"
            // def check = sh(returnStdout: true, script: "curl -u 'tasks:redhat1' -H \"Accept: application/json\" -X GET ${route}/ws/tasks/1").trim()
            // def expected = '{"id":1,"title":"my-task","ownerName":"tasks"}'
            
            // echo "check = ${check}"
            // echo "expected = ${expected}"
            
            // assert check == expected : "Build failed because check:\n${check}\n\ndid not equal\n${expected}"
            
            // sh "curl -i -u 'tasks:redhat1' -X DELETE ${route}/ws/tasks/1"
          }

          // Copy Image to Nexus Docker Registry
          stage('Copy Image to Nexus Docker Registry') {
            echo "Copy image to Nexus Docker Registry"
            sh "skopeo copy --src-tls-verify=false --dest-tls-verify=false --screds=openshift:${token}  --dcreds=admin:admin123 docker://docker-registry.default.svc.cluster.local:5000/mrc-tasks-dev/tasks:${devTag} docker://nexus-registry-mrc-nexus.apps.muc.example.opentlc.com/mrc-tasks-dev/tasks:${devTag}"
          }

          // Blue/Green Deployment into Production
          // -------------------------------------
          // Do not activate the new version yet.
          def destApp   = "tasks-green"
          def activeApp = ""

          def curDeployment = "tasks-green"
          def desiredDeployment = "tasks-blue"

          stage('Blue/Green Production Deployment') {
            // TBD
            curDeployment = sh(returnStdout: true, script: "oc get route tasks --template='{{ .spec.to.name }}' -n mrc-tasks-prod").trim()
            desiredDeployment = "tasks-blue"
            
            // note that we want the *inactive* one
            if (curDeployment == "tasks-blue"){
                desiredDeployment = "tasks-green"
            } else if (curDeployment =="tasks-green") {
                desiredDeployment = "tasks-blue"
            } else{
                echo curDeployment
            }
            
            sh "oc delete configmap ${desiredDeployment}-config -n mrc-tasks-prod --ignore-not-found"
            sh "oc create configmap ${desiredDeployment}-config --from-file=./configuration/application-users.properties --from-file=./configuration/application-roles.properties -n mrc-tasks-prod"
            sh "oc set image dc/${desiredDeployment} ${desiredDeployment}=docker-registry.default.svc:5000/mrc-tasks-dev/tasks:${devTag} -n mrc-tasks-prod"
            
            openshiftDeploy apiURL: masterURL
                  , authToken: token
                  , depCfg: desiredDeployment
                  , namespace: 'mrc-tasks-prod'

            openshiftVerifyDeployment apiURL: masterURL
                  , authToken: token
                  , depCfg: desiredDeployment
                  , namespace: 'mrc-tasks-prod' // FIXME: correct namespace
                  , replicaCount: '1'
                  , verbose: 'false'
                  , verifyReplicaCount: 'true'

            openshiftVerifyService apiURL: masterURL
                  , authToken: token
                  , namespace: 'mrc-tasks-prod' // FIXME: correct namespace
                  , svcName: desiredDeployment
                  , verbose: 'false'
            
          }

          stage('Switch over to new Version') {
            
            // No pause for confirmation here; we want full automation

            echo "Switching Production application to ${destApp}."
            sh "oc set route-backends tasks ${desiredDeployment}=1 ${curDeployment}=0 -n mrc-tasks-prod"
          }
        }

        // Convenience Functions to read variables from the pom.xml
        // Do not change anything below this line.
        // --------------------------------------------------------
        def getVersionFromPom(pom) {
          def matcher = readFile(pom) =~ '<version>(.+)</version>'
          matcher ? matcher[0][1] : null
        }
        def getGroupIdFromPom(pom) {
          def matcher = readFile(pom) =~ '<groupId>(.+)</groupId>'
          matcher ? matcher[0][1] : null
        }
        def getArtifactIdFromPom(pom) {
          def matcher = readFile(pom) =~ '<artifactId>(.+)</artifactId>'
          matcher ? matcher[0][1] : null
        }
}
