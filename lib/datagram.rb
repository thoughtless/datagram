require "datagram/version"

require 'coffee-script'
require 'sinatra'
require 'sequel'
require 'haml'
require 'json'

require 'v8'

module Datagram
  Sequel::Model.plugin :json_serializer

  db = Sequel.connect(ENV['QUERY_DATABASE_URL'])

  class Query < Sequel::Model
  end

  class App < Sinatra::Base
    set :public_dir, 'public'

    get '/' do
      if Query.count == 0
        content = """/*
Enter your SQL query below.
You can run, save, or delete queries using the buttons above
*/

SELECT *
FROM users
"""

        filter = """// Enter your JavaScript filter below.
// Filters modify the returned SQL dataset
// Query results are available for manipulation
// via the global variable `results`. Your filtered
// results will be used to build the report.
[results[0]]
"""

        name = 'default query'

        Query.create :content => content, :filter => filter, :name => name
      end

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

    get '/queries/:id' do |id|
      if query = Query[id]
        status 200

        @ds = self.class.reporting_db.fetch(query.content)
        results = @ds.to_a

        context = V8::Context.new

        context['results'] = results
        context['filter'] = query.filter
        context['filteredResults'] = context.eval('JSON.stringify(eval(filter))')

        body(context['filteredResults'])
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

    # assets
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
