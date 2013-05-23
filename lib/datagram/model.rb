require 'sequel'

module Datagram
  module Model
    # Default sqlite3 database location for storing queries.
    QUERY_DATABASE_URL = 'sqlite://datagram.db'

    # Returns the migration path for the CLI.
    MIGRATION_PATH = File.expand_path('../../../db/migrate', __FILE__)

    Sequel::Model.plugin :json_serializer

    # Database that stores queries against the reporting database.
    def self.query_db
      @query_db ||= Sequel.connect(ENV['QUERY_DATABASE_URL'] || QUERY_DATABASE_URL)
    end

    # Migrate the Datagram query database.
    def self.migrate(options={})
      # Load the database.
      db = Datagram::Model.query_db

      # Now load the extension.
      Sequel.extension :migration

      # If we're forcing the migrations, lets drop all the tables
      if options[:force]
        Datagram.logger.info "Destroying `#{db.uri}`"
        db.destroy
      end

      # Now lets run the migrations
      Datagram.logger.info "Migrating `#{db.uri}`"
      Sequel::Migrator.apply(db, Datagram::Model::MIGRATION_PATH)
    end

    class Query < Sequel::Model(Datagram::Model.query_db)
    end
  end
end
