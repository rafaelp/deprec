# Copyright 2008-2009 by Rafael Lima (http://rafael.adm.br). All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 

  namespace :deprec do
    namespace :ruby_enterprise do
            
      SRC_PACKAGES[:ruby_enterprise] = {
        :filename => 'ruby-enterprise-1.8.6-20081215.tar.gz',   
        :md5sum => "aab57b7d5061c1980bec5dbe311ec9b2  ruby-enterprise-1.8.6-20081215.tar.gz", 
        :dir => 'ruby-enterprise-1.8.6-20081215',  
        :url => "http://rubyforge.org/frs/download.php/48623/ruby-enterprise-1.8.6-20081215.tar.gz",
        :unpack => "tar zxf ruby-enterprise-1.8.6-20081215.tar.gz;",
        :configure => '',
        :make => '',
        :install => 'echo -en "\n\n\n\n" | ./installer;'
      }
      
      desc "Install Ruby Enterprise Edition for using with Passenger"
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:ruby_enterprise], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:ruby_enterprise], src_dir)
        set_as_default
      end
      
      task :install_deps do
        apt.install( {:base => %w(libmysqlclient15-dev build-essential ruby1.8-dev libreadline5-dev)}, :stable )
      end
      
      desc "Set Ruby Enterprise as default Ruby interpreter"
      task :set_as_default do
        run 'echo "export PATH=\"/opt/ruby-enterprise-1.8.6-20081215/bin/:\$PATH\"" | sudo tee /etc/profile.d/ruby-enterprise.sh'
        sudo 'ln -sf /opt/ruby-enterprise-1.8.6-20081215/bin/erb /usr/local/bin/'
        sudo 'ln -sf /opt/ruby-enterprise-1.8.6-20081215/bin/rake /usr/local/bin/'
        sudo 'ln -sf /opt/ruby-enterprise-1.8.6-20081215/bin/gem /usr/local/bin/'
        sudo 'ln -sf /opt/ruby-enterprise-1.8.6-20081215/bin/irb /usr/local/bin'
        sudo 'ln -sf /opt/ruby-enterprise-1.8.6-20081215/bin/rails /usr/local/bin/'
        sudo 'ln -sf /opt/ruby-enterprise-1.8.6-20081215/bin/rdoc /usr/local/bin/'
        sudo 'ln -sf /opt/ruby-enterprise-1.8.6-20081215/bin/ri /usr/local/bin/'
        sudo 'ln -sf /opt/ruby-enterprise-1.8.6-20081215/bin/ruby /usr/local/bin/'
      end
      
      namespace :rubygems do

        SRC_PACKAGES[:rubygems] = {
          :md5sum => "a04ee6f6897077c5b75f5fd1e134c5a9  rubygems-1.3.1.tgz", 
          :url => "http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz",
  	      :configure => "",
  	      :make =>  "",
          :install => '/opt/ruby-enterprise-1.8.6-20081215/bin/ruby setup.rb;'
        }

        task :install do
          install_deps
          deprec2.download_src(SRC_PACKAGES[:rubygems], src_dir)
          deprec2.install_from_src(SRC_PACKAGES[:rubygems], src_dir)
          # gem2.upgrade #  you may not want to upgrade your gems right now
          # If we want to selfupdate then we need to 
          # create symlink as latest gems version is broken
          # gem2.update_system
          # sudo ln -s /usr/bin/gem1.8 /usr/bin/gem
        end

        # install dependencies for rubygems
        task :install_deps do
        end

      end 
      
      
      namespace :passenger do

        set :passenger_install_dir, '/opt/ruby-enterprise-1.8.6-20081215/lib/ruby/gems/1.8/gems/passenger-2.0.6'
        set(:passenger_document_root) { "#{current_path}/public" }
        set :passenger_rails_allow_mod_rewrite, 'off'
        set :passenger_vhost_dir, '/etc/apache2/sites-enabled'
        # Default settings for Passenger config files
        set :passenger_log_level, 0
        set :passenger_user_switching, 'on'
        set :passenger_default_user, 'nobody'
        set :passenger_max_pool_size, 6
        set :passenger_max_instances_per_app, 0
        set :passenger_pool_idle_time, 300
        set :passenger_rails_autodetect, 'on'
        set :passenger_rails_spawn_method, 'smart' # smart | conservative
        set :passenger_ruby_dir, '/opt/ruby-enterprise-1.8.6-20081215/bin/ruby'

        SYSTEM_CONFIG_FILES[:ruby_enterprise] = [

          {:template => 'passenger.erb',
            :path => '/etc/apache2/conf.d/passenger',
            :mode => 0755,
            :owner => 'root:root'}

        ]
        
        desc "Install Passenger using Ruby Enterprise Edition"
        task :install do
          install_deps
          apt.install( {:base => %w(apache2-mpm-prefork apache2-prefork-dev)}, :stable )
          sudo 'echo -en "\n\n" | sudo /opt/ruby-enterprise-1.8.6-20081215/bin/passenger-install-apache2-module;'
        end

        task :install_deps do
          top.deprec.ruby_enterprise.rubygems.install
          sudo '/opt/ruby-enterprise-1.8.6-20081215/bin/gem install --no-rdoc --no-ri  rake'
        end

        desc "Generate Passenger apache configs (system level) from template."
        task :config_gen do
          SYSTEM_CONFIG_FILES[:ruby_enterprise].each do |file|
            deprec2.render_template(:ruby_enterprise, file)
          end
        end

        desc "Push Passenger configs (system level) to server"
        task :config, :roles => :passenger do
          deprec2.push_configs(:ruby_enterprise, SYSTEM_CONFIG_FILES[:ruby_enterprise])
        end
      
      end
    end
  end  
end
