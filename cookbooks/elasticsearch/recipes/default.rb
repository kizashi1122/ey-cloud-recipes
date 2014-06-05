#
# Cookbook Name:: elasticsearch
# Recipe:: default
#
# Credit goes to GoTime for their original recipe ( http://cookbooks.opscode.com/cookbooks/elasticsearch )

if ['util'].include?(node[:instance_role])
  if node['utility_instances'].empty?
    Chef::Log.info "No utility instances found"
  else
    elasticsearch_instances = []
    elasticsearch_expected = 0
    node['utility_instances'].each do |elasticsearch|
      if elasticsearch['name'].include?("elasticsearch_")
        elasticsearch_expected = elasticsearch_expected + 1 unless node['fqdn'] == elasticsearch['hostname']
        elasticsearch_instances << "#{elasticsearch['hostname']}:9300" unless node['fqdn'] == elasticsearch['hostname']
      end
    end
  end

  Chef::Log.info "Downloading Elasticsearch v#{node['elasticsearch']['version']} checksum #{node['elasticsearch']['checksum']}"
  remote_file "/tmp/elasticsearch-#{node['elasticsearch']['version']}.zip" do
    source "http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-#{node['elasticsearch']['version']}.zip"
    mode "0644"
    checksum node['elasticsearch']['checksum']
    not_if { File.exists?("/tmp/elasticsearch-#{node['elasticsearch']['version']}.zip") }
  end

  group node['elasticsearch']['group'] do
    action :create
    system true
  end

  user "elasticsearch" do
    comment "ElasticSearch User"
    home "#{node['elasticsearch']['home']}"
    shell "/bin/bash"
    uid 61021
    gid node['elasticsearch']['group']
    supports :manage_home => false
    action :create
    system true
  end

  #
  # Create service
  # 
  template "/etc/init.d/elasticsearch" do
    source "elasticsearch.init.erb"
    owner 'root' and mode 0755
  end

  service "elasticsearch" do
    supports :status => true, :restart => true
    action [ :enable ]
  end
  

  # Update JAVA as the Java on the AMI can sometimes crash

  # Chef::Log.info "Updating Sun JDK"
  # package "dev-java/sun-jdk" do
  #   version "1.6.0.26"
  #   action :upgrade
  # end

  Chef::Log.info "Updating JDK to 1.7"
  enable_package "dev-java/icedtea-bin" do
    version "7.2.3.3-r1 ~amd64"
  end

  package "dev-java/icedtea-bin" do
    version "7.2.3.3-r1"
    action :install
  end

  enable_package "virtual/jdk" do
    version "1.7.0"
  end

  package "virtual/jdk" do
    version "1.7.0"
    action :install
  end

  bash "set java7" do
    user "root"
    cwd "/tmp"
    code "eselect java-vm set system icedtea-bin-7"
  end

  directory "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}" do
    owner "elasticsearch"
#    owner "root"
    group "elasticsearch"
    mode 0755
  end

#  ["/var/log/elasticsearch", "/var/lib/elasticsearch", "/var/run/elasticsearch"].each do |dir|
  ["#{node['elasticsearch']['path']['data']}", "#{node['elasticsearch']['path']['logs']}"].each do |dir|
    directory dir do
#      owner "root"
      owner "elasticsearch"
      group "elasticsearch"
      mode "0755"
      recursive true
    end
  end

  bash "unzip elasticsearch" do
    user "root"
    cwd "/tmp"
    code %(unzip /tmp/elasticsearch-#{node['elasticsearch']['version']}.zip)
    not_if { File.exists? "/tmp/elasticsearch-#{node['elasticsearch']['version']}" }
  end

  bash "copy elasticsearch root" do
    user "root"
    cwd "/tmp"
    code %(cp -r /tmp/elasticsearch-#{node['elasticsearch']['version']}/* /usr/lib/elasticsearch-#{node['elasticsearch']['version']})
    not_if { File.exists? "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}/lib" }
  end


  #
  # create plugins directoryr explicitly.
  # config directory is originally created so you need not create it.
  #
  directory "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}/plugins" do
      owner "elasticsearch"
      group "elasticsearch"
 #   owner "root"
 #   group "root"
    mode "0755"
  end

  link "/usr/lib/elasticsearch" do
    to "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}"
  end

  # directory "#{node[:elasticsearch_home]}" do
  #   owner "elasticsearch"
  #   group "nogroup"
  #   mode 0755
  # end

  # directory "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}/data" do
  #   owner "root"
  #   group "root"
  #   mode 0755
  #   action :create
  #   recursive true
  # end

  #
  # mount????
  #
  # mount "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}/data" do
  #   device "#{node[:elasticsearch_home]}"
  #   fstype "none"
  #   options "bind,rw"
  #   action :mount
  # end

  template "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}/config/logging.yml" do
    source "logging.yml.erb"
    mode "0644"
  end

  

  # directory "/usr/share/elasticsearch" do
  #   owner "elasticsearch"
  #   group "elasticsearch"
  #   mode 0755
  # end
  # max_mem = ((node[:memory][:total].to_i / 1024 * 0.75)).to_i.to_s + "m"

  #
  # This file is put under config directory. It is easy to find.
  # It is loaded as shell variable ES_INCLUDE. See /etc/init.d/elasticsearch
  # So you don't have to put it under /usr/share/elasticsearch.
  #
  template "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}/config/elasticsearch.in.sh" do
    source "elasticsearch.in.sh.erb"
    mode "0644"
    backup 0
#    variables(
#      :es_max_mem => ((node[:memory][:total].to_i / 1024 * 0.75)).to_i.to_s + "m"
#    )
  end

  # include_recipe "elasticsearch::s3_bucket"
  template "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}/config/elasticsearch.yml" do
    source "elasticsearch.yml.erb"
    owner "elasticsearch"
    group "elasticsearch"
    mode "0600"
    backup 0
  #   variables(
  #     :aws_access_key => node[:aws_secret_key],
  #     :aws_access_id => node[:aws_secret_id],
  #     :elasticsearch_s3_gateway_bucket => node[:elasticsearch_s3_gateway_bucket],
  #     :elasticsearch_instances => elasticsearch_instances.join('", "'),
  #     :elasticsearch_defaultreplicas => node[:elasticsearch_defaultreplicas],
  #     :elasticsearch_expected => elasticsearch_expected,
  #     :elasticsearch_defaultshards => node[:elasticsearch_defaultshards],
  #     :elasticsearch_clustername => node[:elasticsearch_clustername]
  #   )
  end

  #
  # install plugins
  #
  bash "install elasticsearch-plugin kuromoji" do
    user "root"
    cwd "/tmp"
    code %(/usr/lib/elasticsearch/bin/plugin -install elasticsearch/elasticsearch-analysis-kuromoji/2.2.0)
    not_if { File.exists? "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}/plugins/analysis-kuromoji" }
  end

  bash "install elasticsearch-plugin head" do
    user "root"
    cwd "/tmp"
    code %(/usr/lib/elasticsearch/bin/plugin -install mobz/elasticsearch-head)
    not_if { File.exists? "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}/plugins/head" }
  end

  bash "install elasticsearch-plugin HQ" do
    user "root"
    cwd "/tmp"
    code %(/usr/lib/elasticsearch/bin/plugin -install royrusso/elasticsearch-HQ)
    not_if { File.exists? "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}/plugins/HQ" }
  end

  bash "install elasticsearch-plugin marvel" do
    user "root"
    cwd "/tmp"
    code %(/usr/lib/elasticsearch/bin/plugin -install elasticsearch/marvel/latest)
    not_if { File.exists? "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}/plugins/marvel" }
  end

  bash "install elasticsearch-plugin inquisitor" do
    user "root"
    cwd "/tmp"
    code %(/usr/lib/elasticsearch/bin/plugin -install polyfractal/elasticsearch-inquisitor)
    not_if { File.exists? "/usr/lib/elasticsearch-#{node['elasticsearch']['version']}/plugins/inquisitor" }
  end

  template "/etc/monit.d/elasticsearch_#{node['environment']['name']}.monitrc" do
    source "elasticsearch.monitrc.erb"
    owner "elasticsearch"
    group "elasticsearch"
    backup 0
    mode "0644"
  end

  # Tell monit to just reload, if elasticsearch is not running start it.  If it is monit will do nothing.
  execute "monit reload" do
    command "monit reload"
  end

end


# This portion of the recipe should run on all instances in your environment.  We are going to drop elasticsearch.yml for you so you can parse it and provide the instances to your application.
if ['solo','app_master','app','util'].include?(node[:instance_role])
  elasticsearch_hosts = []
  node['utility_instances'].each do |elasticsearch|
    if elasticsearch['name'].include?("elasticsearch_")
      elasticsearch_hosts << "#{elasticsearch['hostname']}:9200"
    end

    node.engineyard.apps.each do |app|
      template "/data/#{app.name}/shared/config/elasticsearch.yml" do
        owner node[:owner_name]
        group node[:owner_name]
        mode "0660"
        source "es.yml.erb"
        backup 0
        variables(:yaml_file => {
          node.engineyard.environment.framework_env => { 
          :hosts => elasticsearch_hosts} })
      end
    end
  end
end
