ARG BUILD_FROM
#FROM $BUILD_FROM
#Remove when fixed : https://community.home-assistant.io/t/cant-install-local-add-on/276366/3 and use #FROM $BUILD_FROM
FROM hassioaddons/base-armv7:8.0.6

MAINTAINER Lucas DRAGO <lucas_drago@hotmail.fr>


SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV LANG C.UTF-8
RUN apk update && apk add --no-cache bash jq iw hostapd networkmanager net-tools sudo dhcp && rm -rf /var/cache/apk/*

COPY hostapd.conf /
RUN echo "iface wlan0 inet static" > /etc/network/interfaces
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
