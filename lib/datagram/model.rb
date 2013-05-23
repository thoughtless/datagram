require 'sequel'

module Datagram
  module Model
    Sequel::Model.plugin :json_serializer

    # Database that stores queries against the reporting database.
    def self.query_db
      @query_db ||= Sequel.connect(ENV['QUERY_DATABASE_URL'])
    end

    # Returns the migration path for the CLI.
    def self.migration_path
      File.expand_path('../../../db/migrate', __FILE__)
    end

    class Query < Sequel::Model(Datagram::Model.query_db)
    end
  end
end
