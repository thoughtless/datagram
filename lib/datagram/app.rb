require 'coffee-script'
require 'sinatra'
require 'sequel'
require 'haml'
require 'json'
require 'v8'

module Datagram
  class App < Sinatra::Base
    set :public_dir, File.expand_path('../public', __FILE__)

    enable :logging

    include Datagram::Model

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

      @schema = {}

      self.class.reporting_db.tables.each do |table|
        column_name = self.class.reporting_db.schema(table).map {|item| item.first}

        @schema[table] = column_name
      end

      @queries = Query.all

      haml :index
    end

    get '/run' do
      @content = params[:content]
      @filter = params[:filter] || ''

      begin
        @ds = self.class.reporting_db.dataset.with_sql(@content)

        # gross way to make sure we get
        # float formatted results rather
        # than scientific notation
        results = format(@ds)

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
        @ds = self.class.reporting_db.fetch(query.content)
        results = @ds.to_a

        context = V8::Context.new

        context['results'] = results
        context['filter'] = query.filter
        context['filteredResults'] = context.eval('JSON.stringify(eval(filter))')

        status 200

        if context['filteredResults'].nil?
          body(results.to_json)
        else
          body(context['filteredResults'])
        end
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

    # Remove the datagram query from the database.
    delete '/queries/:id' do |id|
      @query = Query[id]
      @query.destroy

      status 204
    end

    get '/queries/:id/download' do |id|
      @query = Query[id]
      queryName = @query.name || "Query #{id}"

      @ds = self.class.reporting_db.fetch(@query.content)

      headers "Content-Disposition" => "attachment;filename=#{queryName}.csv"

      @ds.to_csv
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
    def format(results)
      results.to_a.map do |row|
        hash = {}

        row.each_pair do |col_name, value|
          if value.class == BigDecimal
            hash[col_name] = value.to_f
          else
            hash[col_name] = value
          end
        end

        hash
      end
    end

    def self.reporting_db
      @reporting_db ||= Sequel.connect(ENV['REPORTING_DATABASE_URL']).tap do |db|
        db.logger = Datagram.logger
      end
    end
  end
end
