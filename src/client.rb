require "socket"
require "json"

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
    join_message = {
      :type => "JOINING_NETWORK",
      :node_id => "#{ARGV[0]}",
      :ip_address => "192.168.1"
    }
    @request = Thread.new do
      @server.puts(JSON.generate(join_message))
      loop {
         @server.puts($stdin.gets.chomp)
      }
    end
  end
end

server = TCPSocket.open("localhost",ARGV[1]||8767)
Client.new(server)
