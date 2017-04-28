# This image expects a set of environment variables to parameterize the build:
#
#   OUTPUT_REGISTRY - the Docker registry URL to push this image to
#   VERSION - the version of image to be built
#   BASE_IMAGE_NAME - the name of the base image 
#   OPENSHIFT_NAMESPACES - the reposistory name of the image to be built
#   SOURCE_REPOSITORY - a URI to fetch the build context from
#   SOURCE_REF - a reference to pass to Git for which commit to use (optional)
#
# This image expects to have the Docker socket bind-mounted into the container.
# If "/root/.dockercfg" is bind mounted in, it will use that as authorization
# to a Docker registry.
#
FROM core/centos:7

MAINTAINER qujinping

RUN rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    yum install -y epel-release && \
    yum install -y --setopt=tsflags=nodocs gettext docker automake make python-setuptools python-pip git && \
    yum clean all && \
    (curl -L https://github.com/openshift/source-to-image/releases/download/v1.1.5/source-to-image-v1.1.5-4dd7721-linux-386.tar.gz | \
         tar -xz -C /usr/local/bin ) 

LABEL io.k8s.display-name="OpenShift Origin Custom Builder" \
      io.k8s.description="This is a custom builder for use to build s2i images."
ENV HOME=/root
COPY build.sh /tmp/build.sh
CMD ["/tmp/build.sh"]
