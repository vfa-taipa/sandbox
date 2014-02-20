require 'socket'
sock = UDPSocket.new
# data = 'I sent this'
# sock.send(data, 0, '127.0.0.1', 33333)
(1..500).each do |i|
	msg = "#{i}"
	sock.send(msg, 0, '54.199.132.106', 8888)
	sleep 0.02
end
sock.close