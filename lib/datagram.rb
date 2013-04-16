require "datagram/version"

require 'coffee-script'
require 'sinatra'
require 'sequel'
require 'haml'
require 'json'

module Datagram
  Sequel::Model.plugin :json_serializer

  db = Sequel.connect(ENV['QUERY_DATABASE_URL'])

  class Query < Sequel::Model
  end

  class App < Sinatra::Base
    set :public_dir, 'public'

    get '/' do
      @queries = Query.all

      haml :index
    end

    get '/run' do
      @content = params[:content]
      @filter = params[:filter] || ''

      begin
        @ds = self.class.reporting_db.fetch(@content)
        results = @ds.to_a

        status 200
        body({:columns => @ds.columns, :items => results}.to_json)
      rescue Sequel::Error => e
        status 500
        body({:message => e.message}.to_json)
      end
    end

    post '/queries' do
      @content = params[:content]
      @filter = params[:filter] || ''
      @name = params[:name] || ''

      if query = Query.create(:content => @content, :filter => @filter, :name => @name)
        status 200
        body(query.to_json)
      end
    end

    put '/queries/:id' do |id|
      if query = Query[id]
        name = params[:name] || "Query #{id}"
        content = params[:content] || ''
        filter = params[:filter] || ''

        query.update_all :name => name, :content => content, :filter => filter

        status 200
        body(query.to_json)
      end
    end

    delete '/queries/:id' do |id|
      @query = Query[id]

      @query.destroy

      status 204
    end

    get '/style.css' do
      content_type 'text/css', :charset => 'utf-8'
      sass :style
    end

    get '/application.js' do
      coffee :application
    end

  private
    def self.reporting_db
      @reporting_db ||= Sequel.connect(ENV['REPORTING_DATABASE_URL'])
    end
  end
end
