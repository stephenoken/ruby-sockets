# require "socket"
#
# class Server
#   def initialize(port,ip)
#     @server = TCPServer.open(port)
#     @connections = {}
#     @rooms = {}
#     @clients = {}
#   end
#
#   def run
#     loop {
#       Thread.start(@server.accept) do | client |
#         nick_name = client.gets.chomp.to_sym
#         @connections[:clients].each do | other_name, other_client |
#           if nick_name == other_name || client == other_client
#             client.puts "This username already exists"
#             Thread.kill self
#           end
#         end
#         puts "#{nick_name} #{client}"
#         @connections[:clients][nick_name] = client
#         client.puts "Connection established, Thank you for joining! Happy chatting"
#       end
#     }
#   end
# end
# server = Server.new("192.168.92.53", 3000)
# server.run()

# require "socket"
#
# socket = TCPSocket.new('localhost',3000)
# client = socket.accept
#
# puts "New client! #{client}"
#
# client.write("Hello from server")
# client.close

require "socket"

server = TCPServer.open(2000)
loop {
  Thread.start(server.accept) do |client|
    client.puts(Time.now.ctime)
    client.puts "Closing the connection."
    client.close
  end
}
