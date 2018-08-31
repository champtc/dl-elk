#
# Cookbook Name:: dl-elk
# Recipe:: default
#
# Copyright 2017, Champion Technology Company
#
# All rights reserved - Do Not Redistribute
#

#time
package 'ntp'

execute 'ntpd on' do
 action :run
 command 'systemctl enable ntpd.service'
end

execute 'ntpd start' do
 action :run
 command 'systemctl start ntpd.service'
end

#SET SELINUX
execute 'set selinux to permissive' do
 action :run
 command 'sed -i "s/enforcing/permissive/g" /etc/selinux/config'
end

#basic tools
package 'wget'
package 'net-tools'

execute 'install java' do
 action :run
 command 'yum install java -y'
end

#repos
#elasticsearch
cookbook_file '/etc/yum.repos.d/elasticsearch.repo' do
  source 'elasticsearch.repo'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

package 'elasticsearch'

execute 'elasticsearch startup' do
 action :run
 command '/bin/systemctl enable elasticsearch.service'
end

#kibana
cookbook_file '/etc/yum.repos.d/kibana.repo' do
  source 'kibana.repo'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

package 'kibana'

execute 'kibana startup' do
 action :run
 command '/bin/systemctl enable kibana.service'
end

#epel-release
package 'epel-release'

#Nginx
package 'nginx'

execute 'nginx startup' do
 action :run
 command '/bin/systemctl enable nginx.service'
end

#httpd-tools
package 'httpd-tools'

execute 'kibana default' do
 action :run
 command 'htpasswd -b -c /etc/nginx/htpasswd.users kibanaadmin password'
end

#nginx configuration
cookbook_file '/etc/nginx/nginx.conf' do
  source 'nginx.conf'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

#kibana configuration
cookbook_file '/etc/nginx/conf.d/kibana.conf' do
  source 'kibana.conf'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

#repo
#logstash
cookbook_file '/etc/yum.repos.d/logstash.repo' do
  source 'logstash.repo'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

package 'logstash'

cookbook_file '/etc/logstash/conf.d/champion_logstash_config.tar' do
  source 'champion_logstash_config.tar'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

execute 'tar config' do
 action :run
 command 'tar -xvf /etc/logstash/conf.d/champion_logstash_config.tar -C /etc/logstash/conf.d/'
end

execute 'logstash startup' do
 action :run
 command '/bin/systemctl enable logstash.service'
end

#logstash plugins
execute 'plugin install tld' do
 action :run
 command '/usr/share/logstash/bin/logstash-plugin install logstash-filter-tld'
end

execute 'update plugins' do
 action :run
 command '/usr/share/logstash/bin/logstash-plugin update'
end

#geoip update
cookbook_file '/etc/logstash/geo-update.bash' do
  source 'geo-update.bash'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

execute 'geoip folder' do
 action :run
 command 'mkdir /var/local/geoip'
end

execute 'geoip update' do
 action :run
 command 'sh /etc/logstash/geo-update.bash'
end

execute 'geoip cron' do
 action :run
 command 'crontab -l | { cat; echo "0 12 * * 3 /etc/Logstash/geo-update.bash > /dev/null 2>&1"; } | crontab -'
end

#disable firewall
execute 'disable firewall' do
 action :run
 command 'systemctl stop firewalld && systemctl disable firewalld'
end

#restart nginx
execute 'restart nginx' do
 action :run
 command 'systemctl restart nginx'
end
 
#restart kibana
execute 'restart kibana' do
 action :run
 command 'systemctl restart kibana.service' 
end

#restart elasticsearch
execute 'restart elasticsearch' do
 action :run
 command 'systemctl restart elasticsearch.service'
end
 
#restart logstash
execute 'restart logstash' do
 action :run
 command 'systemctl restart logstash.service'
end
