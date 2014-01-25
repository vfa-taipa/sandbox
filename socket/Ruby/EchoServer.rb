module EchoServer
  def post_init
    @buf = ''
  end
  def receive_data(data)
    @buf << data
    if @buf =~ /^.+?\r?\n/
      send_data "You said: #{@buf}"
      close_connection_after_writing
end end
end
require 'eventmachine'
EM.run do
  EM.start_server '0.0.0.0', 2202, EchoServer
end