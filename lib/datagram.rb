require "datagram/version"

require 'sinatra'
require 'sequel'
require 'haml'
require 'json'

module Datagram
  class App < Sinatra::Base
    get '/' do
      # @test = self.class.query_db.fetch('select * from queries;')

      if @sql = params[:sql]
        @ds = self.class.reporting_db.fetch(@sql)
      end
      haml :index
    end

    get '/style.css' do
      content_type 'text/css', :charset => 'utf-8'
      sass :style
    end

  private
    def self.reporting_db
      @reporting_db ||= Sequel.connect(ENV['REPORTING_DATABASE_URL'])
    end

    def self.query_db
      @query_db ||= Sequel.connect(ENV['QUERY_DATABASE_URL'])
    end
  end
end
