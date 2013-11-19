# Datagram

Gist for SQL Queries.

## Installation

Datagram is a rack app that requires database migrations to get working. The application works with two datebases:

* `QUERY_DATABASE_URL` - The database that Datagram stores queries that people write.
* `REPORTING_DATABASE_URL` - The database that Datagram runs queriest against. *Make sure this is being accessed via a read-only database account*

### Install the gem

Add this line to your application's Gemfile:

    gem 'datagram'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install datagram

## Create the query database and migrate to the most recent schema

Datagram stores queries in a Sqlite3 database by default. To setup the database run:

```sh
$ datagram migrate
```

and the Sqlite3 database will be created and/or updated. To change the location of the database, change the `QUERY_DATABASE_URL` variable like:

```sh
$ QUERY_DATABASE_URL=mysql://127.0.0.1:5000/ datagram migrate
```

### Create a rackup file

Datagram is a rack application. To start using, create a rackup file like:

```ruby
require 'datagram'

# The app we've all been waitin for!
run Datagram::App.new
```

Refer to the [`config.ru`](./config.ru) for a development environment friendly version of this configuration.

### Run the server

Now its time to run the server. Configuration happens via environmental variables that is documented in this projects [`.env`](./.env) file.

```sh
$ QUERY_DATABASE_URL=sqlite://datagram.db \
  REPORTING_DATABASE_URL=mysql2://read-only-user:password@127.0.0.1/my-database \
  rackup config.ru
```

Now visit the website and you should be ready to write some queries!

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
