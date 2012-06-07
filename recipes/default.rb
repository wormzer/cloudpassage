#
# Cookbook Name:: cloudpassage
# Recipe:: default
#
# Copyright 2012, Escape Studios
#

#add CloudPassage repository
case node[:platform]
	when "debian", "ubuntu"
		#apt
		command = "echo 'deb http://packages.cloudpassage.com/#{node[:cloudpassage][:repository_key]}/debian debian main' | sudo tee /etc/apt/sources.list.d/cloudpassage.list > /dev/null"
	when "redhat", "centos", "fedora"
		#yum
		command = "echo '[cloudpassage]\nname=CloudPassage production\nbaseurl=http://packages.cloudpassage.com/#{node[:cloudpassage][:repository_key]}/redhat/$basearch\ngpgcheck=1' | sudo tee /etc/yum.repos.d/cloudpassage.repo > /dev/null"
end

execute "add-cloudpassage-repository" do
	command "#{command}"
	action :run
end

#import CloudPassage public key
case node[:platform]
	when "debian", "ubuntu"
		#install curl
		package "curl" do
			action :install
		end

		command = "curl http://packages.cloudpassage.com/cloudpassage.packages.key | sudo apt-key add -"
		gpg_key_already_installed = "sudo apt-key list | grep cloudpassage"
	when "redhat", "centos", "fedora"
		command = "sudo rpm --import http://packages.cloudpassage.com/cloudpassage.packages.key"
		gpg_key_already_installed = "sudo rpm -qa gpg-pubkey* | xargs -i rpm -qi {} | grep cloudpassage"
end

execute "import-cloudpassage-public-key" do
	command "#{command}" 
	action :run
	not_if gpg_key_already_installed
end

#update repositories
case node[:platform]
	when "debian", "ubuntu"
		command = "sudo apt-get update"
	when "redhat", "centos", "fedora"
		command = "sudo yum update --assumeyes"
end

execute "update-repositories" do
	command "#{command}" 
	action :run
end

#install the daemon
package "cphalo" do
	action :install
	notifies :start, "service[cphalod]", :immediately
end

#start the daemon
service "cphalod" do
	start_command "sudo /etc/init.d/cphalod start --api-key=#{node[:cloudpassage][:license_key]}"
	stop_command "service cphalod stop"
	status_command "service cphalod status"
	restart_command "service cphalod restart"
	supports [:start, :stop, :status, :restart]
	#starts the service if it's not running and enables it to start at system boot time
	action [:enable, :start]
end