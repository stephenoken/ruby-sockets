require "socket"

class Client
  def initialize(server)
    @server = server
    @server.puts "Connected"
    @response = nil
    listen
    @response.join
  end

  def listen
    puts "Hello"
    @response =Thread.new do
      loop {
        puts @server.gets.chomp
      }
    end
  end
end

server = TCPSocket.open("localhost",2000)
Client.new(server)
