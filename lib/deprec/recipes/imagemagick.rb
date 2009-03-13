# Copyright 2009 by Rafael Lima (http://rafael.adm.br). All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :imagemagick do

      desc "Install ImageMagick"
      task :install do
        apt.install( {:base => %w(imagemagick libmagick++9-dev)}, :stable )
      end
      
    end 
  end
end
