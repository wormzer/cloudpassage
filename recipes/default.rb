#
# Cookbook Name:: cloudpassage
# Recipe:: default
#
# Copyright 2012, Escape Studios
#

case node[:platform]
	when "debian", "ubuntu"
		#add CloudPassage repository
		execute "add-cloudpassage-repository" do
			command "echo 'deb http://packages.cloudpassage.com/#{node[:cloudpassage][:repository_key]}/debian debian main' | sudo tee /etc/apt/sources.list.d/cloudpassage.list > /dev/null"
			action :run
		end

		#install curl
		package "curl" do
		  action :install
		end

		#import CloudPassage public key
		execute "import-cloudpassage-public-key" do
			command "curl http://packages.cloudpassage.com/cloudpassage.packages.key | sudo apt-key add -"
			action :run
		end

		#update apt repositories
		execute "apt-get-update" do
			command "apt-get update"
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
end