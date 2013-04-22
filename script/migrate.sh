# Migrate to version specified (IntegerMigrator style migrations)
sequel -m db/migrate -M $1 sqlite://db/datagram_development.db
