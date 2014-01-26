#!/usr/bin/env ruby

require 'rubygems' # or use Bundler.setup
require 'eventmachine'

class SimpleChatServer < EM::Connection

  @@connected_clients = Array.new
  DM_REGEXP           = /^@([a-zA-Z0-9]+)\s*:?\s*(.+)/.freeze

  attr_reader :username
  attr_reader :roomid


  # ============================================================
  # EventMachine handlers
  # ============================================================

  def post_init
    @username = nil
    @roomid = nil

    puts "A client has connected..."
    ask_username
  end

  def unbind
    @@connected_clients.delete(self)
    puts "[info] #{@username} has left" if entered_username?
  end

  def receive_data(data)
    if !entered_username?
      handle_username(data.strip)
    elsif !entered_room?
      handle_room(data.strip)
    else
      handle_chat_message(data.strip)
    end
  end


  # ============================================================
  # Username handling
  # ============================================================

  def entered_username?
    !@username.nil? && !@username.empty?
  end # entered_username?

  def handle_username(input)
    if input.empty?
      send_line("Blank usernames are not allowed. Try again.")
      ask_username
    else
      @username = input
      @@connected_clients.push(self)
      self.other_peers.each { |c| c.send_data("#{@username} has joined the room\n") }
      puts "#{@username} has joined"

      self.send_line("[info] Ohai, #{@username}")
      self.ask_userroom
    end
  end # handle_username(input)

  def ask_username
    self.send_line("[info] Enter your username:")
  end # ask_username

  # ============================================================
  # Username Room
  # ============================================================

  def entered_room?
    !@roomid.nil? && !@roomid.empty?
  end # entered_room?

  def handle_room(input)
    if input.empty?
      send_line("Blank RoomID are not allowed. Try again.")
      ask_userroom
    else
      @roomid = input
    end
  end # handle_username(input)

  def ask_userroom
    self.send_line("[info] Enter your Room ID:")
  end # ask_username


  # ============================================================
  # Message handling
  # ============================================================

  def handle_chat_message(msg)
    if command?(msg)
      self.handle_command(msg)
    else
      if direct_message?(msg)
        self.handle_direct_message(msg)
      else
        #self.announce(msg, "#{@username}:")
        self.announce_to_group(msg, "#{@username}:", @roomid)
      end
    end
  end # handle_chat_message(msg)

  def direct_message?(input)
    input =~ DM_REGEXP
  end # direct_message?(input)

  def handle_direct_message(input)
    username, message = parse_direct_message(input)

    if connection = @@connected_clients.find { |c| c.username == username }
      puts "[dm] @#{@username} => @#{username}"
      connection.send_line("[dm] @#{@username}: #{message}")
    else
      send_line "@#{username} is not in the room. Here's who is: #{usernames.join(', ')}"
    end
  end # handle_direct_message(input)

  def parse_direct_message(input)
    return [$1, $2] if input =~ DM_REGEXP
  end # parse_direct_message(input)


  # ============================================================
  # Commands handling
  # ============================================================

  def command?(input)
    input =~ /(exit|status)$/i
  end # command?(input)

  def handle_command(cmd)
    case cmd
    when /exit$/i   then self.close_connection
    when /status$/i then self.send_line("[chat server] It's #{Time.now.strftime('%H:%M')} and there are #{self.number_of_connected_clients} people in the room")
    end
  end # handle_command(cmd)


  # ============================================================
  # Helpers
  # ============================================================

  def announce(msg = nil, prefix = "[chat server]")
    @@connected_clients.each { |c| c.send_line("#{prefix} #{msg}") } unless msg.empty?
  end # announce(msg)

  def announce_to_group(msg = nil, prefix = "[chat server]", roomid = nil)
    connection = @@connected_clients.select { |c| c.roomid == roomid }
    connection.each { |c| c.send_line("#{prefix} #{msg}") } unless msg.empty?
  end

  def number_of_connected_clients
    @@connected_clients.size
  end # number_of_connected_clients

  def other_peers
    @@connected_clients.reject { |c| self == c }
  end # other_peers

  def send_line(line)
    self.send_data("#{line}\n")
  end # send_line(line)

  def usernames
    @@connected_clients.map { |c| c.username }
  end # usernames
end

EventMachine.run do
  # hit Control + C to stop
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EventMachine.start_server("0.0.0.0", 10000, SimpleChatServer)
end