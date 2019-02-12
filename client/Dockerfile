FROM centos:7

# install necessary libs
RUN yum clean all \
    && yum install -y epel-release \
    && yum install -y openvpn

# Add the openvpn client config file
COPY openvpn.conf /etc/openvpn/

COPY start.sh /opt/openvpn-tunnel

CMD ["/opt/openvpn-tunnel/start.sh"]
