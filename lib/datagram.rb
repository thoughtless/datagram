require "datagram/version"

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

    post '/queries' do
      @content = params[:content]
      @filter = params[:filter] || ''
      @name = params[:name] || ''

      if query = Query.create(:content => @content, :filter => @filter, :name => @name)
        status 200
        body(query.to_json)
      end
    end

    get '/run' do
      @content = params[:content]
      @filter = params[:filter] || ''

      @ds = self.class.reporting_db.fetch(@content)
      results = @ds.to_a

      status 200
      body({:columns => @ds.columns, :items => results}.to_json)
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

  private
    def self.reporting_db
      @reporting_db ||= Sequel.connect(ENV['REPORTING_DATABASE_URL'])
    end
  end
end
