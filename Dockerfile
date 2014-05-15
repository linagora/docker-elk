#Kibana

FROM ubuntu:14.04
 
RUN  apt-get update

#Prevent daemon start during install
RUN	echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && \
    chmod +x /usr/sbin/policy-rc.d

#Supervisord
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor && \
	mkdir -p /var/log/supervisor
CMD ["/usr/bin/supervisord", "-n"]

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server && \
	mkdir /var/run/sshd && chmod 700 /var/run/sshd && \
	echo 'root:root' |chpasswd && \
	sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
	sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config && \
	sed -ri 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y less nano ntp net-tools inetutils-ping curl git telnet openjdk-7-jre-headless tzdata-java

#ElasticSearch
RUN wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.1.0.tar.gz && \
    tar xf elasticsearch-*.tar.gz && \
    rm elasticsearch-*.tar.gz && \
    mv elasticsearch-* elasticsearch && \
    elasticsearch/bin/plugin -install mobz/elasticsearch-head

#Kibana
RUN wget https://download.elasticsearch.org/kibana/kibana/kibana-3.0.0.tar.gz && \
    tar xf kibana-*.tar.gz && \
    rm kibana-*.tar.gz && \
    mv kibana-* kibana

#NGINX
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common && \
    add-apt-repository ppa:nginx/stable && \
    echo 'deb http://packages.dotdeb.org squeeze all' >> /etc/apt/sources.list && \
    curl http://www.dotdeb.org/dotdeb.gpg | apt-key add - && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

#Logstash
RUN wget https://download.elasticsearch.org/logstash/logstash/logstash-1.4.0.tar.gz && \
	tar xf logstash-*.tar.gz && \
    rm logstash-*.tar.gz && \
    mv logstash-* logstash

#Configuration
ADD ./ /docker-elk
RUN cd /docker-elk && \
    mkdir /opush && \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.saved && \
    cp nginx.conf /etc/nginx/nginx.conf && \
    cp supervisord-kibana.conf /etc/supervisor/conf.d && \
    cp opush /logstash/patterns/opush && \
    cp logstash-forwarder.crt /logstash/logstash-forwarder.crt && \
    cp logstash-forwarder.key /logstash/logstash-forwarder.key && \
    cp opush_stats.json /kibana/app/dashboards/opush_stats.json

#80=ngnx, 9200=elasticsearch
EXPOSE 22 80 9200
