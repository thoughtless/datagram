require "datagram/version"

require 'sinatra'
require 'sequel'
require 'haml'
require 'json'

module Datagram
  class App < Sinatra::Base
    get '/' do
      if @sql = params[:sql]
        @ds = db.fetch(@sql)
      end
      haml :index
    end

  private
    def db
      @db ||= Sequel.connect(ENV['DATABASE_URL'])
    end
  end
end