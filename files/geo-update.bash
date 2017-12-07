#!/bin/bash

# Downloads the latest GeoLight DBs from maxmind.
# Updates/replaces the databases that logstash uses.
# These are the IP-to-location databases that logstash uses.
# Maxmind updates them once a month on the first Tuesday of the month.
# See http://dev.maxmind.com/geoip/legacy/geolite/

echo Beginning update of GeoIP databases for logstash.
cd /tmp

#remove previously downloaded files in temp
rm -f GeoLite2-City.mmdb.gz GeoLite2-City.mmdb 
#rm -f GeoIPASNum.dat.gz GeoIPASNum.dat GeoLiteCity.dat.gz GeoLiteCity.dat
echo Downloading latest files.

#retrieve the geo files
#wget --quiet --output-document GeoIPASNum.dat.gz http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz || { echo 'Download of GeoIPASNum.dat.gz failed' ; exit 1; }
wget --quiet --output-document GeoLite2-City.mmdb.gz http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz || { echo 'Download of GeoLite2-City.mmdb.gz failed' ; exit 1; }

echo Unzipping

#unzup the files and change permissions
#gunzip GeoIPASNum.dat.gz
gunzip GeoLite2-City.mmdb.gz

echo Setting permissions
chmod 664 GeoLite2-City.mmdb
#chmod 664 GeoIPASNum.dat GeoLiteCity.dat
chown logstash:logstash GeoLite2-City.mmdb
#chown logstash:logstash GeoIPASNum.dat GeoLiteCity.dat

DBPATH="/var/local/geoip"

#replace the current geoip files with the new ones and backing up the old ones
echo Replacing existing files and backing up the old in DB ${DBPATH}.
cd "$DBPATH"

#.mmdb to .mmdb.bak indicates backups and move geoip files from /tmp to current DBPATH
#if dir currently has .mmdb files, make them .bak and move from temp
if [ -e "GeoLite2-City.mmdb" ]; then
#if [ -e "GeoIPASNum.dat" ] && [ -e "GeoLiteCity.dat" ]; then
#	mv -f GeoIPASNum.dat GeoIPASNum.dat.bak && mv /tmp/GeoIPASNum.dat .
	mv -f GeoLite2-City.mmdb GeoLite2-City.mmdb.bak && mv /tmp/GeoLite2-City.mmdb .
#	mv -f GeoLiteCity.dat GeoLiteCity.dat.bak && mv /tmp/GeoLiteCity.dat .

#else just move from /tmp
else
#	mv /tmp/GeoIPASNum.dat .
	mv /tmp/GeoLite2-City.mmdb .
fi

echo Restarting logstash
# Modify for your distro services model.
service logstash restart

echo Done
