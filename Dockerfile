# Fault needs swift
FROM swift:centos7

# For Chisel
RUN yum install -y java-1.8.0-openjdk-devel java-1.8.0-openjdk \
    && yum install -y python3 python3-devel \
    && yum install -y perl-core \
    && rm -f /etc/yum.repos.d/bintray-rpm.repo \
    && curl -L https://www.scala-sbt.org/sbt-rpm.repo > /etc/yum.repos.d/sbt-rpm.repo \
    && yum install -y sbt

# For OpenROAD flow
RUN yum update -y \
    && yum group install -y "Development Tools" \
    && yum install -y https://www.klayout.org/downloads/CentOS_7/klayout-0.27.1-0.x86_64.rpm \
    && yum install -y libXScrnSaver libXft libffi-devel python3 python3-pip qt5-qtbase tcl time which \
    && pip3 install pandas

WORKDIR /OpenROAD-flow-scripts

COPY --from=openroad/yosys /install ./tools/install/yosys
COPY --from=openroad/centos7-builder-gcc /OpenROAD/build/src/openroad ./tools/install/OpenROAD/bin/openroad
COPY --from=openroad/centos7-builder-gcc /OpenROAD/etc/DependencyInstaller.sh /etc/DependencyInstaller.sh
RUN /etc/DependencyInstaller.sh -runtime
COPY --from=openroad/lsoracle /LSOracle/build/core/lsoracle ./tools/build/LSOracle/bin/lsoracle
COPY --from=openroad/lsoracle /LSOracle/core/test.ini ./tools/build/LSOracle/share/lsoracle/test.ini
COPY --from=openroad/lsoracle /LSOracle/build/yosys-plugin/oracle.so /OpenROAD-flow/tools/build/yosys/share/yosys/plugins/
COPY ./submodules/OpenROAD-flow-scripts/setup_env.sh .
COPY ./submodules/OpenROAD-flow-scripts/flow ./flow
RUN chmod o+rw -R /OpenROAD-flow-scripts

WORKDIR /

# For ASSUE
RUN yum install -y epel-release \
    && yum install -y iverilog

# Update git version
RUN yum install -y https://repo.ius.io/ius-release-el7.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && yum remove -y git \
    && yum install -y git224

# For Fault
RUN pip3 install pyverilog

WORKDIR /opt
RUN git clone https://github.com/Cloud-V/Fault.git && cd Fault && swift install.swift

# For ABC
RUN yum install -y readline-devel

WORKDIR /root