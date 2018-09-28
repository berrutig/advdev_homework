GUID=$1
USER=$2
SESSION_TOKEN=$3

echo "Jenkins docker script... using ${GUID}, ${USER} and token: ${SESSION_TOKEN}"

# Backup existing registries.conf to /etc/containers/registries.conf.yyyyMMddHHMM
echo "Backup existing registries.conf to /etc/containers/registries.conf.yyyyMMddHHMM"
cp /etc/containers/registries.conf /etc/containers/registries.conf.$(date +%Y%m%d%H%M)
cd /home/$2/AnanthRHAdvDevHomework/Infrastructure/bin
command cp -fr registries.conf /etc/containers/

echo "Enabling Docker and Starting Docker service"
systemctl enable docker
systemctl start docker

echo "Docker services started..."

command rm -r /home/${USER}/jenkins-slave-appdev
mkdir /home/${USER}/jenkins-slave-appdev
cd  /home/${USER}/jenkins-slave-appdev

echo "FROM docker.io/openshift/jenkins-slave-maven-centos7:v3.9
USER root
RUN yum -y install skopeo apb && \
    yum clean all
USER 1001" > Dockerfile
echo "Docker file created"...

docker build . -t docker-registry-default.apps.na39.openshift.opentlc.com/${GUID}-jenkins/jenkins-slave-maven-appdev:v3.9 && \
echo "Docker build completed..."

skopeo copy --dest-tls-verify=false --dest-creds=${USER}:${SESSION_TOKEN} docker-daemon:docker-registry-default.apps.na39.openshift.opentlc.com/${GUID}-jenkins/jenkins-slave-maven-appdev:v3.9 docker://docker-registry-default.apps.na39.openshift.opentlc.com/${GUID}-jenkins/jenkins-slave-maven-appdev:v3.9
echo "skopeo copy to Docker registry successful..."
