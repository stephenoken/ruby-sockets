# require "socket"
#
# class Client
#   def initialize(server)
#     @server = server
#     @request = nil
#     @response = nil
#     listen
#     send
#     @request.join
#     @response.join
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

def sendMessage (server)
  loop {
    puts "Send Message: "
    server.puts $stdin.gets.chomp
  }
end

s = TCPSocket.open(hostname, port)

s.puts "Connected"

# sendMessage(s)

while line = s.gets
  puts line.chomp
end
s.close
