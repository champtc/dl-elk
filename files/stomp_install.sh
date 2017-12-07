#!/bin/sh
# Download ActiveMQ and place in /opt
cd /tmp
wget http://archive.apache.org/dist/activemq/5.15.0/apache-activemq-5.15.0-bin.tar.gz
tar xzvf apache-activemq-5.15.0-bin.tar.gz
mv apache-activemq-5.15.0 /opt
ln -sf /opt/apache-activemq-5.15.0/ /opt/activemq

# Create ActiveMQ user
adduser --system activemq
chown -R activemq: /opt/apache-activemq-5.15.0/

# Set the managementContext element to true in opt/activemq/conf/activemq.xml
echo "Changing /opt/activemq/conf/activemq.xml managementContext to true..."
cp /opt/activemq/conf/activemq.xml /opt/activemq/conf/activemq.xml.backup
sed -i 's/createConnector="false"/createConnector="true"/' /opt/activemq/conf/activemq.xml

# Install service scripts
echo Creating services...
echo " creating activemq start script..."
touch /etc/init.d/activemqstart.sh
echo -e "#!/bin/bash \nexport JAVA_HOME=/usr \n/opt/activemq/bin/activemq start" >> /etc/init.d/activemqstart.sh
echo " creating activemq stop  script..."
touch /etc/init.d/activemqstop.sh
echo -e "#!/bin/bash \nexport JAVA_HOME=/usr \n/opt/activemq/bin/activemq stop" >> /etc/init.d/activemqstop.sh
echo " creating activemq"
touch /etc/init.d/activemq
echo -e "#!/bin/bash\n#\n# activemq	Starts ActiveMQ.\n#\n# chkconfig: 345 88 12\n# description: ActiveMQ is a JMS Messaging Queue Server.\n### BEGIN INIT INFO\n# Provides: \$activemq\n### END INIT INFO\n" >> /etc/init.d/activemq
echo -e "# Source function library" >> /etc/init.d/activemq
echo -e ". /etc/init.d/functions\n" >> /etc/init.d/activemq
echo -e "[ -f /etc/init.d/activemqstart.sh ] || exit 0" >> /etc/init.d/activemq
echo -e "[ -f /etc/init.d/activemqstop.sh ] || exit 0" >> /etc/init.d/activemq
echo -e "\nRETVAL=0" >> /etc/init.d/activemq
echo -e "\numask 077" >> /etc/init.d/activemq
echo -e "\nstart() {" >> /etc/init.d/activemq
echo -e "	echo -n $\"Starting ActiveMQ: \"" >> /etc/init.d/activemq
echo -e "	/etc/init.d/activemqstart.sh" >> /etc/init.d/activemq
echo -e "	echo" >> /etc/init.d/activemq
echo -e "	return \$RETVAL" >> /etc/init.d/activemq
echo -e "}" >> /etc/init.d/activemq
echo -e "stop() {" >> /etc/init.d/activemq
echo -e "	echo -n $\"Shutting down ActiveMQ: \"" >> /etc/init.d/activemq
echo -e "	/etc/init.d/activemqstop.sh" >> /etc/init.d/activemq
echo -e "	echo" >> /etc/init.d/activemq
echo -e "	return \$RETVAL" >> /etc/init.d/activemq
echo -e "}" >> /etc/init.d/activemq
echo -e "restart() {" >> /etc/init.d/activemq
echo -e "	stop && start" >> /etc/init.d/activemq
echo -e "}" >> /etc/init.d/activemq
echo -e "case \"\$1\" in" >> /etc/init.d/activemq
echo -e "start)" >> /etc/init.d/activemq
echo -e "	start" >> /etc/init.d/activemq
echo -e "	;;" >> /etc/init.d/activemq
echo -e "stop)" >> /etc/init.d/activemq
echo -e "	stop" >> /etc/init.d/activemq
echo -e "	;;" >> /etc/init.d/activemq
echo -e "restart|reload)" >> /etc/init.d/activemq
echo -e "	restart" >> /etc/init.d/activemq
echo -e "	;;" >> /etc/init.d/activemq
echo -e "*)" >> /etc/init.d/activemq
echo -e "	echo $\"Usage: \$0 {start|stop|restart}\"" >> /etc/init.d/activemq
echo -e "	exit 1" >> /etc/init.d/activemq
echo -e "esac" >> /etc/init.d/activemq
echo -e "\nexit \$?" >> /etc/init.d/activemq
# Note: EOF

# Permissions
echo "Setting permissions..."
chmod +x /etc/init.d/activemq
chmod +x /etc/init.d/activemqstart.sh
chmod +x /etc/init.d/activemqstop.sh
chkconfig --add activemq
chkconfig activemq on

# Start ActiveMQ
echo "Starting ActiveMQ service..."
service activemq start
# Status check
echo "Status check on the service..."
/opt/activemq/bin/activemq list
# Port check
echo "Check port 61616..."
netstat -an | grep 61616
# Set TTL to 5 minutes
if grep -Fq "ttl to 5 minutes" /opt/activemq/conf/active.xml
then
	echo "TTL already set to 5 minutes. Skipping..."
else
	echo "Setting the TTL to 5 minutes..."
	sed -i '/<broker xmlns="http:\/\/activemq.apache.org\/schema\/core" brokerName="localhost" dataDirectory="${activemq.data}">/a \ \t<plugins>\n\t\t<!-- If not already set, set ttl to 5 minutes -->\n\t\t<timeStampingBrokerPlugin zeroExpirationOverride="300000"\/>\n\t<\/plugins>' /opt/activemq/conf/activemq.xml
fi


# Add the virtual destination, Champ.Ingest
if grep -Fq "Champ.Ingest" /opt/activemq/conf/activemq.xml
then
	echo "Virtual destination: Champ.Ingest already present. Skipping..."
else
	echo "adding the virtual destination: Champ.Ingest in /opt/activemq/conf/activemq.xml"	
	sed -i '/<\/destinationPolicy>/a \ \n\t<!--\n\t  Create a virtual destination called Champ.Ingest\n\t  that directs all messages to a queue and a topic both called "Champ.Ingest.Item"\n\t-->\n\t  <destinationInterceptors>\n\t\t<virtualDestinationInterceptor>\n\t\t\t<virtualDestinations>\n\t\t\t\t<compositeQueue name="Champ.Ingest">\n\t\t\t\t\t<forwardTo>\n\t\t\t\t\t\t<queue physicalName="Champ.Ingest.Item.Queue" \/>\n\t\t\t\t\t\t<topic physicalName="Champ.Ingest.Item" \/>\n\t\t\t\t\t<\/forwardTo>\n\t\t\t\t<\/compositeQueue>\n\n\t\t\t\t<compositeQueue name="Champ.Ingest.4624">\n\t\t\t\t\t<forwardTo>\n\t\t\t\t\t\t<queue physicalName="Champ.Ingest.Item.4624" \/>\n\t\t\t\t\t\t<topic physicalName="Champ.Ingest.Item.4624" \/>\n\t\t\t\t\t<\/forwardTo>\n\t\t\t\t<\/compositeQueue>\n\t\t\t<\/virtualDestinations>\n\t\t<\/virtualDestinationInterceptor>\n\t  <\/destinationInterceptors>' /opt/activemq/conf/activemq.xml
fi
echo "If all looks good, check the web GUI at http;//192.168.5.242:8161/admin/"
echo -e "Default credentials:\n User: admin\n Pass: admin"
echo Done! 