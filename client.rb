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
        res = "Server: #{@server.gets.chomp.to_s}"
        puts res
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

server = TCPSocket.open("localhost",ARGV[0]||2000)
Client.new(server)
