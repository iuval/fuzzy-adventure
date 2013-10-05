ROOT_DIR = File.expand_path('..', File.dirname(__FILE__))
$:.unshift(ROOT_DIR)

require 'rubygems'
require 'sinatra'
require "sinatra/namespace"
require 'mongoid'
require 'will_paginate_mongoid'
include WillPaginate::Sinatra::Helpers

ENV['RACK_ENV'] ||= 'development'

# --- Declare app module and class ---
module CrystalClash; end

class CrystalClash::App < Sinatra::Base
  # Set views path
  set :views, File.expand_path("app/views", ROOT_DIR)

  register Sinatra::Namespace

  configure do
    Mongoid.configure do |config|
      if ENV['RACK_ENV'] && ENV['RACK_ENV'] == 'production'
        config.sessions = { default: { uri: ENV['MONGOHQ_URL'] } }
      else
        config.sessions = { default: { uri: 'mongodb://localhost:27017/cristalclash' } }
      end
    end
  end
end
# Load models/helpers/routes
Dir["./app/models/*.rb"].sort.each {|file| require file }
Dir["./app/routes/*.rb"].sort.each {|file| require file }
Dir["./app/helpers/*.rb"].sort.each {|file| require file }

CrystalClash::Helpers::Players.init_adjs File.read(File.expand_path('public/adjs.txt', ROOT_DIR)).split("\n")
CrystalClash::Helpers::Players.init_super_adjs File.read(File.expand_path('public/super_adjs.txt', ROOT_DIR)).split("\n")
CrystalClash::Helpers::Players.init_objects File.read(File.expand_path('public/objects.txt', ROOT_DIR)).split("\n")

