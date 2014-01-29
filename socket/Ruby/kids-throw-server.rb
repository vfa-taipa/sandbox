#!/usr/bin/env ruby

require 'rubygems' # or use Bundler.setup
require 'eventmachine'
require 'json'

class SimpleChatServer < EM::Connection

  @@connected_clients = Array.new
  DM_REGEXP           = /^@([a-zA-Z0-9]+)\s*:?\s*(.+)/.freeze

  attr_reader :username
  attr_reader :roomid
  attr_reader :lastupdate


  # ============================================================
  # EventMachine handlers
  # ============================================================

  def post_init
    @username = nil
    @roomid = nil
    @buf = ''
    @lastupdate = Time.now

    @@connected_clients.push(self)

    puts "A client has connected..."
  end

  def unbind
    @@connected_clients.delete(self)
    puts "[info] #{@username} has left"

    #Call API here for user lost connect or close connection
  end

  def receive_data(data)
    @lastupdate = Time.now
    @buf << data
    if @buf =~ /^.+?\r?\n/
      if @buf.match(/^PONG/) == nil then
        self.handle_command(@buf)
      end
      @buf = ''
    end
  end

  # ============================================================
  # Command handling
  # message format : {"cmd":1, "roomid":"","userid":"","content":""}
  # Update user info : {"cmd":2, "roomid":"123","userid":"", "content":""}
  # Send msg to room : {"cmd":3, "roomid":"123","userid":"", "content":"PHAM ANH TAI"}
  # ============================================================
  def handle_command(data)
    puts(data)
    cmd = JSON.parse(data)
    if (cmd["cmd"] == 1) then
      puts("cmd 1 \n")
    elsif (cmd["cmd"] == 2) then
      puts("cmd 2 \n")
      self.setUserInfo(cmd)
    elsif (cmd["cmd"] == 3) then
      puts("cmd 3 \n")
      self.send_to_group(cmd["content"], "", @roomid)
    end
  end

  # ============================================================
  # UserInfo handling
  # ============================================================
  def setUserInfo(cmd)
    @username = cmd["userid"]
    @roomid = cmd["roomid"]
  end

  # ============================================================
  # Helpers
  # ============================================================
  def send_line(line)
    self.send_data("#{line}\n")
  end # send_line(line)

  def send_to_group(msg = nil, prefix = "[chat server]", roomid = nil)
    connection = @@connected_clients.select { |c| c.roomid == roomid }
    connection = connection.reject { |c| self == c }
    connection.each { |c| c.send_line("#{prefix} #{msg}") } unless msg.empty?
  end

  def self.checkTimeOut
    connection = @@connected_clients.select {|c| Time.now - c.lastupdate > 10}
    connection.each { |c|
      puts("Lastupdate > 10 : #{c.username}")
      c.close_connection
    }
    connection = @@connected_clients.select {|c| Time.now - c.lastupdate > 5}
    connection.each { |c|
      puts("#{Time.now} - Lastupdate > 5 : #{c.username}")
      c.send_line("PING")
    }
  end
end

EM.kqueue #MacOS
#EventMachine.epoll #Linux

EM.run do
  # hit Control + C to stop
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EM.start_server("0.0.0.0", 8080, SimpleChatServer)

  EventMachine.add_periodic_timer(4) {
    SimpleChatServer.checkTimeOut
  }
end