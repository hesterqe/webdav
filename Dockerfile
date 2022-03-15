FROM registry.redhat.io/rhel8/httpd-24

ARG WEB_DAV_CONFIG=/etc/httpd/conf.d/webdav.conf \
    COS_MOUNT=/var/www/html/cos \
	WEB_DAV_LOCK_PATH=/var/www/html \
	WEB_DAV_PASSWORD_FILE=/etc/httpd/.htpasswd

# Let the assemble script install the dependencies
RUN /usr/libexec/s2i/assemble

# /var/www/html has to be writeable by apache to create DavLockDB
# DavLockDB may need to be made a shared volume with other apache instances

USER 0

# create supplemental webdav configuration as WEB_DAV_CONFIG
RUN echo "DavLockDB $WEB_DAV_LOCK_PATH/DavLock" >> $WEB_DAV_CONFIG && \
    echo "<VirtualHost *:80>" >> $WEB_DAV_CONFIG && \
    echo "    DocumentRoot $COS_MOUNT/" >> $WEB_DAV_CONFIG && \
    echo "    Alias /cos $COS_MOUNT" >> $WEB_DAV_CONFIG && \
    echo "    <Directory $COS_MOUNT>" >> $WEB_DAV_CONFIG && \
    echo "        DAV On" >> $WEB_DAV_CONFIG && \
    echo "        AuthType Basic" >> $WEB_DAV_CONFIG && \
    echo "        AuthName "webdav"" >> $WEB_DAV_CONFIG && \
    echo "        AuthUserFile $WEB_DAV_PASSWORD_FILE" >> $WEB_DAV_CONFIG && \
    echo "        Require valid-user" >> $WEB_DAV_CONFIG && \
    echo "    </Directory>" >> $WEB_DAV_CONFIG && \
    echo "</VirtualHost>" >> $WEB_DAV_CONFIG && \
	touch $WEB_DAV_PASSWORD_FILE && \
	chmod 0755 $WEB_DAV_CONFIG &&\
    chmod 0755 $WEB_DAV_LOCK_PATH
	
# temporary as this should be a pvc volume instead
RUN mkdir COS_MOUNT && \
    chmod 0755 $COS_MOUNT

USER 1001

# The run script uses standard ways to run the application
CMD /usr/libexec/s2i/run