FROM registry.redhat.io/rhel8/httpd-24

ARG WEB_DAV_CONFIG=/etc/httpd/conf.d/webdav.conf
ARG SSL_CONFIG=/etc/httpd/conf.d/ssl.conf
# ARG SSL_CERT_FILE=
ARG SSL_KEY_FILE=/etc/httpd/tls/localhost.key
ARG SSL_CA_FILE=/etc/httpd/tls/localhost.crt
ARG COS_MOUNT=/var/www/html/cos
ARG WEB_DAV_LOCK_PATH=/var/www/html
ARG WEB_DAV_PASSWORD_FILE=/etc/httpd/.htpasswd

# /var/www/html has to be writeable by apache to create DavLockDB
# DavLockDB may need to be made a shared volume with other apache instances
USER 0

RUN mkdir -p /tmp/src && \
    chown -R 1001:0 /tmp/src

# Let the assemble script install the dependencies
RUN /usr/libexec/s2i/assemble

# create supplemental ssl configuration as SSL_CONFIG
RUN echo "SSLEngine on" >> $SSL_CONFIG && \
    echo "SSLCipherSuite ALL:+TLSv1.2" >> $SSL_CONFIG && \
    echo "SSLCertificateFile $SSL_CERT_FILE" >> $SSL_CONFIG && \
    echo "SSLCertificateKeyFile $SSL_KEY_FILE" >> $SSL_CONFIG && \
    echo "SSLProxyEngine On" >> $SSL_CONFIG && \
    echo "SSLProxyVerify none" >> $SSL_CONFIG && \
    echo "SSLProxyCheckPeerName off" >> $SSL_CONFIG && \
    echo "SSLProxyCheckPeerCN off" >> $SSL_CONFIG && \
    echo "SSLProxyCheckPeerExpire off" >> $SSL_CONFIG && \
#   echo "SSLProxyCACertificateFile $SSL_CA_FILE" >> $SSL_CONFIG && \
    chmod 0755 $SSL_CONFIG && \
# create supplemental webdav configuration as WEB_DAV_CONFIG
    echo "DavLockDB $WEB_DAV_LOCK_PATH/DavLock" >> $WEB_DAV_CONFIG && \
    echo "<VirtualHost *:8080>" >> $WEB_DAV_CONFIG && \
    echo "    DocumentRoot $COS_MOUNT/" >> $WEB_DAV_CONFIG && \
    echo "    Alias /cos $COS_MOUNT" >> $WEB_DAV_CONFIG && \
    echo "    <Directory $COS_MOUNT>" >> $WEB_DAV_CONFIG && \
    echo "        DAV On" >> $WEB_DAV_CONFIG && \
    echo "        AuthType Basic" >> $WEB_DAV_CONFIG && \
    echo "        AuthName webdav" >> $WEB_DAV_CONFIG && \
    echo "        AuthUserFile $WEB_DAV_PASSWORD_FILE" >> $WEB_DAV_CONFIG && \
    echo "        Require valid-user" >> $WEB_DAV_CONFIG && \
    echo "    </Directory>" >> $WEB_DAV_CONFIG && \
    echo "</VirtualHost>" >> $WEB_DAV_CONFIG && \
    touch $WEB_DAV_PASSWORD_FILE && \
    chmod 0755 $WEB_DAV_CONFIG && \
    chmod 0755 $WEB_DAV_LOCK_PATH
	
# temporary as this should be a pvc volume instead
RUN mkdir -p $COS_MOUNT && \
    echo "Hello World" >> $COS_MOUNT/test.html && \
    chmod -R 0755 $COS_MOUNT    
# temporary as this should should be controlled via LDAP or AzureAD
RUN htpasswd -bc /etc/httpd/.htpasswd dev abc123
    
USER 1001

# The run script uses standard ways to run the application
CMD /usr/libexec/s2i/run
