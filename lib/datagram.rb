require "datagram/version"

require 'sinatra'
require 'sequel'
require 'haml'
require 'json'

module Datagram
  class App < Sinatra::Base
    get '/' do
      if @sql = params[:sql]
        @ds = self.class.db.fetch(@sql)
      end
      haml :index
    end

    get '/style.css' do
      content_type 'text/css', :charset => 'utf-8'
      sass :style
    end

  private
    def self.db
      @db ||= Sequel.connect(ENV['DATABASE_URL'])
    end
  end
end