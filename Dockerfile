FROM solita/ubuntu-systemd

RUN apt-get update
RUN apt-get install sysstat lzop liblzo2-dev liblzo2-2 mtx mt-st sg3-utils zlib1g-dev git lsscsi build-essential gawk alien fakeroot linux-headers-$(uname -r) -y

RUN groupadd -r vtl
RUN useradd -r -c "Virtual Tape Library" -d /opt/mhvtl -g vtl vtl -s /bin/bash
RUN mkdir -p /opt/mhvtl
RUN mkdir -p /etc/mhvtl
RUN chown -Rf vtl:vtl /opt/mhvtl
RUN chown -Rf vtl:vtl /etc/mhvtl

ADD . /src/mhvtl/
WORKDIR /src/mhvtl/

RUN cd /src/mhvtl/kernel && make && make install
RUN make && make install
RUN mkdir /etc/tgt

# Check that mhvtl file exists
RUN ls -la /etc/init.d/mhvtl
RUN ls -la /etc/mhvtl/
RUN ls -la /opt/mhvtl/

#CMD ["/bin/bash", "-c", "exec /etc/init.d/mhvtl start"]
CMD ["/bin/bash", "-c", "exec /sbin/init --log-target=journal 3>&1"]

