FROM centos:7

# install necessary libs
RUN yum clean all \
    && yum install -y epel-release \
    && yum install -y openvpn

# Add the openvpn server config file
COPY server.conf /etc/openvpn/openvpn.conf

COPY ccd /etc/openvpn/ccd

COPY start.sh /opt/openvpn-tunnel

# Internally uses port 1194/udp, remap using `docker run -p 1194:1194/udp`
EXPOSE 1194/udp

CMD ["/opt/openvpn-tunnel/start.sh"]
