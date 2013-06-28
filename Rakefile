require 'rubygems'
require 'rake'


$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/app')

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./app/boot"
end

desc "Load application"
task :boot do
  require 'boot'
end
desc "Refresh all saved models to fill in new fields"
task :save_all => [:boot] do
  NeonPm::Models.constants.each do |model_name|
    if model_name != :Observers
      model = NeonPm::Models.const_get(model_name)
      model.each { |inst| inst.save }
    end
  end
end

desc "Database"
namespace :db do
  desc "Insert initial seed objects into database"
  task :seed => [:boot] do
    require './db/seed'
  end

  desc "Remove all data from database"
  task :drop => [:boot] do
    NeonPm::Models.constants.each do |model_name|
      if model_name != :Observers
        model = NeonPm::Models.const_get(model_name)
        model.delete_all
      end
    end
  end
end