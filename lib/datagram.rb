require "datagram/version"

require 'sinatra'
require 'sequel'
require 'haml'
require 'json'

module Datagram
  db = Sequel.connect(ENV['QUERY_DATABASE_URL'])

  class Query < Sequel::Model
  end

  class App < Sinatra::Base
    get '/' do
      if @sql = params[:content]
        @ds = self.class.reporting_db.fetch(@sql)
      end
      haml :index
    end

    post '/queries' do
      if @content = params[:content]
        filter = params[:filter] || ''

        if query = Query.create(:content => @content, :filter => filter)
          redirect "/queries/#{query.values[:id]}"
        else
          p 'kaboom'
        end
      end
    end

    get '/queries/:id' do |id|
      @query = Query[id]

      haml :show
    end

    delete '/queries/:id' do |id|
      @query = Query[id]

      @query.destroy

      redirect '/'
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
