require 'datagram'

use Rack::MethodOverride

run Datagram::App.new
