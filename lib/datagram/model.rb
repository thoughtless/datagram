require 'sequel'

module Datagram
  module Model
    # Default sqlite3 database location for storing queries.
    QUERY_DATABASE_URL = 'sqlite://db/datagram.db'

    # Returns the migration path for the CLI.
    MIGRATION_PATH = File.expand_path('../../../db/migrate', __FILE__)

    Sequel::Model.plugin :json_serializer

    # Database that stores queries against the reporting database.
    def self.query_db
      @query_db ||= Sequel.connect(ENV['QUERY_DATABASE_URL'] || QUERY_DATABASE_URL)
    end

    class Query < Sequel::Model(Datagram::Model.query_db)
    end
  end
end
