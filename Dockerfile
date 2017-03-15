FROM ubuntu:16.04

RUN sed -i -e 's#archive.ubuntu.com#mirrors.kernel.org#' /etc/apt/sources.list && \
    echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 select true' | /usr/bin/debconf-set-selections && \
    echo 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main' >> /etc/apt/sources.list && \
    apt-get update && apt-get install -y --allow-unauthenticated oracle-java8-installer wget curl openssh-server supervisor libssl-dev libbz2-dev libsnappy-dev iputils-ping && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV HADOOP_VERSION '2.7.3'

RUN wget -O /tmp/hadoop.tar.gz "http://apache.cs.utah.edu/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" && \
    mkdir -p /opt/hadoop/ && \
    tar --strip-components=1 -xf /tmp/hadoop.tar.gz -C /opt/hadoop && \
    rm /tmp/hadoop.tar.gz

ADD ./ssh/. /etc/ssh/

ENV PATH $PATH:/opt/hadoop/bin
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV HADOOP_HOME /opt/hadoop


COPY ./entrypoint.sh /entrypoint.sh
COPY ./supervisord.conf /supervisord.conf
COPY ./clustersetup.py /clustersetup.py
COPY ./hadoop-env.sh /opt/hadoop/etc/hadoop/hadoop-env.sh
COPY ./master.conf /master.conf

EXPOSE 22
# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000

# Mapred ports
EXPOSE 10020 19888

# #Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088

VOLUME ["/hdfs"]
ENTRYPOINT ["/entrypoint.sh"]
