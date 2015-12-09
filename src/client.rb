require "socket"

class Client
  def initialize(server)
    @server = server
    @request = nil
    @response = nil
    listen
    send
    @request.join
    @response.join
  end

  def listen
    @response =Thread.new do
      loop {
        res = "Server: #{@server.gets.chomp.to_s}"
        puts res
        if res.include? "Goodbye"
          abort
        end
      }
    end
  end

  def send
    # puts "Enter Command"
    @request = Thread.new do
      loop {
         @server.puts($stdin.gets.chomp)
      }
    end
  end
end

server = TCPSocket.open(ARGV[0]||"localhost",ARGV[1]||8767)
Client.new(server)
