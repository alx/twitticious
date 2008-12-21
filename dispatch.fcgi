#!/usr/bin/ruby

require 'sinatra/lib/sinatra.rb'
require 'rubygems'

fastcgi_log = File.open("fastcgi.log", "a")
STDOUT.reopen fastcgi_log
STDERR.reopen fastcgi_log
STDOUT.sync = true

set :logging, false
set :server, "FastCGI"

module Rack
  class Request
    def path_info
      @env["SCRIPT_URL"].to_s
    end
    def path_info=(s)
      @env["SCRIPT_URL"] = s.to_s
    end
  end
end

load 'twitticious.rb'
