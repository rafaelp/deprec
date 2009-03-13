# Copyright 2008-2009 by Rafael Lima (http://rafael.adm.br). All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :mysql_cluster do

      set :db_roles, [:db_cluster_mgmt, :db_cluster_data, :db_cluster_sql]

      desc "Install mysql cluster"
      task :install, :roles => db_roles do
        install_deps
      end

      # Install dependencies for Mysql Cluster
      task :install_deps, :roles => db_roles do
        apt.install( {:base => %w(mysql-server mysql-client)}, :stable )
        send(run_method, "/etc/init.d/mysql stop")
      end
      
      task :config_gen do
        mgmt.config_gen
        sql.config_gen
        data.config_gen
      end
      
      task :config do
        mgmt.config
        sql.config
        data.config
      end

      task :setup do
        mgmt.start
        mgmt.activate
        sql.setup
        sql.start
        sql.activate
        data.activate
      end

      namespace :mgmt do

        set(:mysql_cluster_mgmt_nodes) { db_cluster_mgmt_hosts }
        set(:mysql_cluster_data_nodes) { db_cluster_data_hosts }
        set :mysql_cluster_data_memory, '80M'
        set :mysql_cluster_index_memory, '18M'      

        # Installation
                
        # Configuration
      
        SYSTEM_CONFIG_FILES[:mysql_cluster_mgmt] = [
        
          {:template => "ndb_mgmd.cnf.erb",
           :path => '/etc/mysql/ndb_mgmd.cnf',
           :mode => 0644,
           :owner => 'root:root'},

        ]
      
        desc "Generate configuration file(s) for mysql from template(s)"
        task :config_gen do
          SYSTEM_CONFIG_FILES[:mysql_cluster_mgmt].each do |file|
            deprec2.render_template(:mysql_cluster, file)
          end
        end
      
        desc "Push mysql config files to server"
        task :config, :roles => :db_cluster_mgmt do
          deprec2.push_configs(:mysql_cluster, SYSTEM_CONFIG_FILES[:mysql_cluster_mgmt])
        end
      
        task :activate, :roles => :db_cluster_mgmt do
          send(run_method, "update-rc.d mysql-ndb-mgm defaults")
        end  
      
        task :deactivate, :roles => :db_cluster_mgmt do
          send(run_method, "update-rc.d -f mysql-ndb-mgm remove")
        end
      
        # Control
      
        desc "Start Mysql Cluster Manager"
        task :start, :roles => :db_cluster_mgmt do
          send(run_method, "/etc/init.d/mysql-ndb-mgm start")
        end
      
        desc "Stop Mysql Cluster Manager"
        task :stop, :roles => :db_cluster_mgmt do
          send(run_method, "/etc/init.d/mysql-ndb-mgm stop")
        end
      
        desc "Restart Mysql Cluster Manager"
        task :restart, :roles => :db_cluster_mgmt do
          send(run_method, "/etc/init.d/mysql-ndb-mgm restart")
        end
      
        desc "Reload Mysql Cluster Manager"
        task :reload, :roles => :db_cluster_mgmt do
          send(run_method, "/etc/init.d/mysql-ndb-mgm reload")
        end
      
      
        task :backup, :roles => :db do
        end
      
        task :restore, :roles => :db do
        end
      end   



      namespace :sql do

        set(:mysql_cluster_mgmt_nodes) { db_cluster_mgmt_hosts }
        set(:mysql_cluser_mgmt_host_ip) { db_cluster_mgmt_hosts.values[0] }
        set :db_roles, :db_cluster_sql
      
        # Installation
        
        task :setup, :roles => db_roles do
          sudo 'mkdir -p /usr/local/mysql/data'
          run 'cd /var/lib/mysql-cluster'
          sudo 'ndbd --initial'
        end
        

        task :change_root_password, :roles => db_roles do
          new_password = Capistrano::CLI.ui.ask("Enter new password for mysql root") { |q| q.echo = false }

          sudo "mysqladmin -u root password #{new_password}"
          sudo "rm ~/.mysql_history"
        end

        # Configuration
      
        SYSTEM_CONFIG_FILES[:mysql_cluster_sql] = [
        
          {:template => "my.cnf.erb",
           :path => '/etc/mysql/my.cnf',
           :mode => 0644,
           :owner => 'root:root'},

        ]
      
        desc "Generate configuration file(s) for mysql cluster sql node from template(s)"
        task :config_gen do
          SYSTEM_CONFIG_FILES[:mysql_cluster_sql].each do |file|
            deprec2.render_template(:mysql_cluster, file)
          end
        end
      
        desc "Push mysql cluster sql node config files to server"
        task :config, :roles => db_roles do
          deprec2.push_configs(:mysql_cluster, SYSTEM_CONFIG_FILES[:mysql_cluster_sql])
        end
      
        task :activate, :roles => db_roles do
          send(run_method, "update-rc.d mysql defaults")
        end  
      
        task :deactivate, :roles => db_roles do
          send(run_method, "update-rc.d -f mysql remove")
        end
      
        # Control
      
        desc "Start Mysql Cluster SQL Node"
        task :start, :roles => db_roles do
          send(run_method, "/etc/init.d/mysql start")
        end
      
        desc "Stop Mysql Cluster SQL Node"
        task :stop, :roles => db_roles do
          send(run_method, "/etc/init.d/mysql stop")
        end
      
        desc "Restart Mysql Cluster SQL Node"
        task :restart, :roles => db_roles do
          send(run_method, "/etc/init.d/mysql restart")
        end
      
        desc "Reload Mysql Cluster SQL Node"
        task :reload, :roles => db_roles do
          send(run_method, "/etc/init.d/mysql reload")
        end
      
      
        task :backup, :roles => db_roles do
        end
      
        task :restore, :roles => db_roles do
        end
      end   


      namespace :data do

        set :db_roles, :db_cluster_data

        # Installation
        

        # Configuration
      
        SYSTEM_CONFIG_FILES[:mysql_cluster_data] = [
        
        ]
      
        desc "Generate configuration file(s) for mysql from template(s)"
        task :config_gen do
          # do nothing
          #SYSTEM_CONFIG_FILES[:mysql_cluster_data].each do |file|
          #  deprec2.render_template(:mysql_cluster, file)
          #end
        end
      
        desc "Push mysql config files to server"
        task :config, :roles => db_roles do
          # do nothing
          #deprec2.push_configs(:mysql_cluster, SYSTEM_CONFIG_FILES[:mysql_cluster_data])
        end
      
        task :activate, :roles => db_roles do
          send(run_method, "update-rc.d mysql-ndb defaults")
        end  
      
        task :deactivate, :roles => db_roles do
          send(run_method, "update-rc.d -f mysql-ndb remove")
        end
      
        # Control
      
        desc "Start Mysql Cluster Data Node"
        task :start, :roles => db_roles do
          send(run_method, "/etc/init.d/mysql-ndb start")
        end
      
        desc "Stop Mysql Cluster Data Node"
        task :stop, :roles => db_roles do
          send(run_method, "/etc/init.d/mysql-ndb stop")
        end
      
        desc "Restart Mysql Cluster Data Node"
        task :restart, :roles => db_roles do
          send(run_method, "/etc/init.d/mysql-ndb restart")
        end
      
        desc "Reload Mysql Cluster Data Node"
        task :reload, :roles => db_roles do
          send(run_method, "/etc/init.d/mysql-ndb reload")
        end
      
        task :backup, :roles => db_roles do
        end
      
        task :restore, :roles => db_roles do
        end
      end


    end
  end
end