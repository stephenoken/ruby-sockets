# require "socket"
#
# class Client
#   def initialize(server)
#     @server = server
#     @request = nil
#     @response = nil
#   end
#
#   def send
#     puts "Enter username:"
#     @request = Thread.new do
#       loop {
#         msg = $stdin.gets.chomp
#         @server.puts(msg)
#       }
#     end
#   end
#
#   def listen
#     @response = Thread.new do
#       loop{
#         msg = @server.gets.chomp
#         puts "#{msg}"
#       }
#     end
#   end
# end
#
# server = TCPSocket.open("localhost",3000)
# Client.new(server)

require "socket"

hostname = 'localhost'
port = 2000

s = TCPSocket.open(hostname, port)

while line = s.gets
  puts line.chomp
end
s.close
