ARG BUILD_FROM
FROM $BUILD_FROM

MAINTAINER Lucas DRAGO <lucas_drago@hotmail.fr>


SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV LANG C.UTF-8
RUN apk update && apk add --no-cache bash jq iw hostapd networkmanager net-tools sudo dhcp && rm -rf /var/cache/apk/*

COPY hostapd.conf /
RUN echo "iface wlan0 inet static" > /etc/network/interfaces
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
