FROM debian:bookworm-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive 

ADD https://download.brother.com/welcome/dlf105200/brscan4-0.4.11-1.amd64.deb /tmp

ADD https://download.brother.com/welcome/dlf006652/brscan-skey-0.3.2-0.amd64.deb /tmp
	

FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive 

RUN apt-get update && apt-get -y --no-install-recommends install \
		sane \
		sane-utils \
		netbase \
		ghostscript \
		netpbm \
		graphicsmagick \
		curl \
		ssh \
		sshpass \
		lighttpd \
        php-cgi \
		iproute2 \
		iputils-ping \
		&& apt-get -y clean

COPY --from=builder /tmp/brscan4-*.deb /tmp
RUN cd /tmp && \
	dpkg -i /tmp/brscan4-*.deb && \
	rm /tmp/brscan4-*.deb

COPY --from=builder /tmp/brscan-skey-*.deb /tmp
RUN cd /tmp && \
	dpkg -i /tmp/brscan-skey-*.deb && \
	rm /tmp/brscan-skey-*.deb

RUN lighty-enable-mod auth || true; \
    lighty-enable-mod fastcgi || true; \
    lighty-enable-mod fastcgi-php || true; \
    lighty-enable-mod access || true

RUN cat <<EOF >> /etc/lighttpd/lighttpd.conf
\$HTTP["url"] =~ "^/lib" {
	url.access-deny = ("")
}
EOF

RUN mkdir -p /var/run/lighttpd
RUN touch /var/run/lighttpd/php-fastcgi.socket
RUN chown -R www-data /var/run/lighttpd

ENV TZ=Etc/UTC

ENV NAME="Scanner"
ENV MODEL="MFC-L2700DW"
ENV IPADDRESS="192.168.1.123"
ENV USERNAME="NAS"

#only set these variables, if inotify needs to be triggered (e.g., for Synology Drive):
ENV SSH_USER=""
ENV SSH_PASSWORD=""
ENV SSH_HOST=""
ENV SSH_PATH=""

#only set these variables, if you need FTP upload:
ENV FTP_USER=""
ENV FTP_PASSWORD=""
ENV FTP_HOST=""
# Make sure this ends in a slash.
ENV FTP_PATH="/scans/" 


COPY files/gui/ /var/www/html
COPY files/api/ /var/www/html

COPY files/runScanner.sh /opt/brother/runScanner.sh
COPY script /opt/brother/scanner/brscan-skey/script

RUN chown -R www-data /var/www/

#directory for scans:
VOLUME /scans

CMD /opt/brother/runScanner.sh