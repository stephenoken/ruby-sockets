require "socket"

class Client
  def initialize(server)
    @server = server
    @response = nil
    @request = nil
    send
    listen
    @response.join
    @request.join
  end

  def listen
    @response =Thread.new do
      loop {
        puts @server.gets.chomp
      }
    end
  end

  def send
    puts "Enter Command"
    @response = Thread.new do
      loop {
         @server.puts($stdin.gets.chomp)
      }
    end
  end
end

server = TCPSocket.open("localhost",2000)
Client.new(server)
