#
# Author:: Daniel DeLeo <dan@kallistec.com>
# Author:: Joshua Timberman <joshua@opscode.com>
#
# Cookbook Name:: rabbitmq
# Recipe:: chef
#
# Copyright 2009, Daniel DeLeo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node[:platform]
when "redhat"
  execute "install rabbitmq-server rpm from URL" do
    command "rpm -Uhv http://www.rabbitmq.com/releases/rabbitmq-server/v2.5.1/rabbitmq-server-2.5.1-1.noarch.rpm"
    action :run
    not_if "rpm -q rabbitmq-server"
  end
else
  execute "install rabbitmq-server deb from URL" do
    command "wget http://www.rabbitmq.com/releases/rabbitmq-server/v2.5.1/rabbitmq-server_2.5.1-1_all.deb; dpkg -i rabbitmq-server_2.5.1-1_all.deb"
    cwd "/tmp"
    not_if "dpkg-query -s rabbitmq-server"
  end
end

service "rabbitmq-server" do
  if platform?("centos","redhat","fedora")
    start_command "/sbin/service rabbitmq-server start &> /dev/null"
    stop_command "/sbin/service rabbitmq-server stop &> /dev/null"
  end
  supports [ :restart, :status ]
  action [ :enable, :start ]
end

# add a chef vhost to the queue
execute "rabbitmqctl add_vhost /chef" do
  not_if "rabbitmqctl list_vhosts| grep /chef"
end

# create chef user for the queue
execute "rabbitmqctl add_user chef testing" do
  not_if "rabbitmqctl list_users |grep chef"
end

# grant the mapper user the ability to do anything with the /chef vhost
# the three regex's map to config, write, read permissions respectively
execute 'rabbitmqctl set_permissions -p /chef chef ".*" ".*" ".*"' do
  not_if 'rabbitmqctl list_user_permissions chef|grep /chef'
end
