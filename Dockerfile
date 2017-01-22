FROM janes/alpine-lamp:latest

MAINTAINER joshhsoj1902

RUN apk add --no-cache  sed \
                        perl \
                        perl-dbi \
                        perl-dbd-mysql \
                        bash

#Download hlxce and configure it
RUN wget -P /tmp/ https://bitbucket.org/Maverick_of_UC/hlstatsx-community-edition/downloads/hlxce_1_6_19.tar.gz \
  && tar -xvf /tmp/hlxce_1_6_19.tar.gz -C /tmp/ \
  && cp -rp /tmp/web/* /www/ \
  && mkdir /var/hlxce \
  && cp -rp /tmp/scripts /var/hlxce \
  && mv /www/updater /www/updater.bac \
  #Web config file
  && sed -i.bak 's/define("DB_HOST", "localhost");/define("DB_HOST", "127.0.0.1");/' /www/config.php \
  && sed -i.bak 's/define("DB_NAME", "");/define("DB_NAME", "hlstatsx");/' /www/config.php \
  && sed -i.bak 's/define("DB_USER", "");/define("DB_USER", "hlxuser");/' /www/config.php \
  && sed -i.bak 's/define("DB_PASS", "");/define("DB_PASS", "hlxpassword");/' /www/config.php \
  #Script config file
  && sed -i.bac 's/DBHost ""/DBHost "127.0.0.1"/' /var/hlxce/scripts/hlstats.conf \
  && sed -i.bac 's/DBUsername ""/DBUsername "hlxuser"/' /var/hlxce/scripts/hlstats.conf \
  && sed -i.bac 's/DBPassword ""/DBPassword "hlxpassword"/' /var/hlxce/scripts/hlstats.conf \
  && sed -i.bac 's/DBName ""/DBName "hlstatsx"/' /var/hlxce/scripts/hlstats.conf \
  #Override log file
  && sed -i.bac 's/local LOG=${LOGDIR}\/hlstats_${PORT}_`date +${LOGDATE_FORMAT}`/local LOG=${LOGDIR}\/hlstats.log/' /var/hlxce/scripts/run_hlstats \
  && ln -sf /dev/stdout /var/hlxce/scripts/hlstats.log \
  #Script need execute
  && chmod +x  /var/hlxce/scripts/hlstats-awards.pl \
            /var/hlxce/scripts/hlstats.pl \
            /var/hlxce/scripts/hlstats-resolve.pl \
            /var/hlxce/scripts/run_hlstats \
  #Update GEOIP file
  && cd /var/hlxce/scripts/GeoLiteCity && ./install_binary.sh \
  #Setup Crons
  && (crontab -u root -l; echo "*/5 * * * * cd /var/hlxce/scripts/ && ./run_hlstats start >/dev/null 2>&1" ) \
    | crontab -u root - \
  && (crontab -u root -l; echo "15 00 * * * cd /var/hlxce/scripts/ && ./hlstats-awards.pl >/dev/null 2>&1" ) \
  | crontab -u root - \
  #Modify start script
  && ln -sf /dev/stdout /var/log/apache2/access.log \
  && sed -i '/tail -f \/var\/log\/apache2\/access.log/c\#Start hlstats script' /start.sh \
  && echo "cd /var/hlxce/scripts && ./run_hlstats start" >> /start.sh \
  && echo "tail -f /var/hlxce/scripts/hlstats.log" >> /start.sh

#Setup MySQL
RUN  sh -c "/usr/bin/mysqld_safe --skip-grant-tables --bind-address 0.0.0.0 --user mysql &" \
  && sleep 10 && mysql -uroot -e "create database hlstatsx;" \
  && mysql -uhlxuser -phlxpassword hlstatsx < /tmp/sql/install.sql \
  && echo "Should likely shutdown mysql cleanly"

VOLUME ["mysql:/var/lib/mysql"]

#CMD ["ogpmanager"]
