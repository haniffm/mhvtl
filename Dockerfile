FROM centos/systemd:latest

RUN rpm --import http://elrepo.org/RPM-GPG-KEY-elrepo.org
RUN yum install -y yum-plugin-fastestmirror
RUN yum -y install https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
RUN yum -y update
RUN yum -y install sg3_utils mt mtx lsscsi

WORKDIR /src/mhvtl

#RUN yum -y install make gcc kernel-devel kernel-utils
RUN yum -y install zlib-devel lzo-devel

# By RPM
ADD kmod-mhvtl-1.5-7.el7.x86_64.rpm /src/mhvtl/
ADD mhvtl-utils-1.5-6.el7.x86_64.rpm /src/mhvtl/
RUN yum -y install epel-release
RUN yum -y install mhvtl-utils-1.5-6.el7.x86_64.rpm kmod-mhvtl-1.5-7.el7.x86_64.rpm


# Workaround for docker/docker#27202, technique based on comments from docker/docker#9212
CMD ["/bin/bash", "-c", "exec /sbin/init --log-target=journal 3>&1"]
