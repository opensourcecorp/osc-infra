FROM debian:unstable

ENV DEBIAN_FRONTEND=noninteractive
ARG VER=2.5.4

RUN apt-get update && apt-get install -y \
      build-essential \
      curl \
      file \
      groff \
      groff-base \
      make \
      tar \
      unzip \
      zip

WORKDIR /root

RUN curl -fsSL -o openldap.tar.gz "https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-${VER}.tgz"
RUN tar -xzf openldap.tar.gz

WORKDIR /root/openldap-${VER}

RUN chmod +x ./configure && ./configure
RUN make depend
RUN make
RUN make test
