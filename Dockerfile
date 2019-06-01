#FROM centos:7.6.1810
FROM 1721900707/mysqltools8:0.0.0.0


MAINTAINER neeky@live.com
#QQ:1721900707
#WeChat: jianglegege
ENV PATH /usr/local/python/bin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG zh_CN.UTF-8

RUN mkdir -p /usr/local/mysqltools8/

WORKDIR /usr/local/mysqltools8/

COPY . /usr/local/mysqltools8/

RUN bash dependences/install_mysqltools8.sh

VOLUME [ "/usr/local/mysqltools8/sps/" ]

