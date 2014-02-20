#!/usr/bin/env ruby


# =======================
# Event Machine UDP
# Test how much data that server can receive
# =======================

require 'rubygems' # or use Bundler.setup
require 'eventmachine'
require 'json'

class UDPHandler < EM::Connection

  @@Clients = Array.new
  @@count = 0

  # ============================================================
  # EventMachine handlers
  # ============================================================
  def receive_data(data)
    data.chomp!
    @@count++;
    puts("Count : #{@@count} - Data : #{data}")
  end
end

#EM.kqueue #MacOS
EM.epoll #Linux

EM.run do
  # hit Control + C to stop
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EM.open_datagram_socket('0.0.0.0', 8888, UDPHandler)
end