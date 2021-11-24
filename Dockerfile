ARG DISTRO=debian
ARG DISTRO_TAG=11.1-slim

FROM ${DISTRO}:${DISTRO_TAG}

ARG AS_PDNS_VERSION=4.5.2

ENV PDNS_setuid=${PDNS_setuid:-pdns} \
  PDNS_setgid=${PDNS_setgid:-pdns} \
  PDNS_daemon=${PDNS_daemon:-no} \
  AS_PDNS_VERSION=${AS_PDNS_VERSION}

RUN apt update \
  && apt -y install g++ make pkg-config libssl-dev libsodium-dev python3-venv \
  python3-pip libboost-dev libboost-serialization-dev libboost-system-dev \
  libboost-thread-dev libboost-context-dev libluajit-5.1-dev \
  && pip3 install --no-cache-dir envtpl

RUN apt -y install libcurl4-openssl-dev netcat-openbsd default-mysql-client default-libmysqlclient-dev libboost-program-options-dev

COPY src/pdns-${AS_PDNS_VERSION}.tar.bz2 /tmp/

COPY files/* /srv/

RUN mv /srv/entrypoint.sh / \
  && cat /tmp/pdns-${AS_PDNS_VERSION}.tar.bz2 | tar xj -C /tmp \
  && cd /tmp/pdns-${AS_PDNS_VERSION} \
  && ./configure --with-modules="bind gmysql" --prefix="" --exec-prefix=/usr --sysconfdir=/etc/pdns \
  --with-libsodium \
  && make \
  && make install \
  && cd / \
  && rm -rf /tmp/pdns-${AS_PDNS_VERSION} \
  && mkdir -p /etc/pdns/conf.d \
  && mkdir -p /var/run/pdns-server \
  && adduser --system --disabled-login --no-create-home --home /tmp --shell /bin/false --group ${PDNS_setgid} 2>/dev/null \
  && chown -R ${PDNS_setuid}:${PDNS_setgid} /etc/pdns/conf.d /var/run/pdns-server

EXPOSE 53/tcp 53/udp 8080/tcp

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/sbin/pdns_server"]
