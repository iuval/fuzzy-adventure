require 'rubygems'
require 'sinatra'
require 'haml'
require 'mongoid'
require 'nokogiri'

ENV['RACK_ENV'] ||= 'development'

configure do
  Mongoid.configure do |config|
    if ENV['RACK_ENV'] && ENV['RACK_ENV'] == 'production'
      config.sessions = { default: { uri: ENV['MONGOHQ_URL'] } }
    else
      config.sessions = { default: { uri: 'mongodb://localhost:27017/cristalclash' } }
    end
  end
end

class Saying
  include Mongoid::Document
  field :wut
  field :who
  field :wen, type: Time, default: Time.now
end

get '/' do
  haml :index
end

get '/list' do
  Saying.all.to_s
end

get '/roulette' do
  haml :roulette, locals: { saying: Saying.all.sample }
end

post '/spread-the-word' do
  return "Don't be leaving empty params..." if params["wut"].empty? || params["who"].empty?

  html_tags = Nokogiri::HTML::DocumentFragment.parse(params["wut"] + params["who"]).search('*')
  return "You wouldn't be trying to submit some code into this pure loving baby, would you...." if html_tags.any?

  if Saying.create(wut: params["wut"], who: params["who"])
    redirect back
  else
    "Does this unformatted text make you feel miserable enough to understand that this is an error?"
  end
end