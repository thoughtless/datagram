require 'thor'

module Datagram
  class CLI < Thor
    desc "migrate [VERSION]", "Migrates the database schema"
    method_options %w( force -f ) => :boolean
    def migrate(version=nil)
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

    desc "version", "Current version of datagram"
    def version
      puts Datagram::VERSION
    end
  end
end
