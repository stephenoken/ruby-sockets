require "socket"
require "json"

class Client
  def initialize()
    # @server = server
    @udp_server = UDPSocket.new
    @request = nil
    @response = nil
    listen
    send
    @request.join
    @response.join
  end

  def listen
    @response =Thread.new do
      # loop {
        data,_ = @udp_server.recvfrom(1024)
        puts "From server #{data}"
        # res = "Server: #{@server.gets.chomp.to_s}"
        # puts res
        # if res.include? "Goodbye"
        #   abort
        # end
      # }
    end
  end

  def send
    # puts "Enter Command"
    join_message = {
      :type => "JOINING_NETWORK",
      :node_id => "#{ARGV[0]}",
      :ip_address => "127.0.0.1"
    }
    network_message = {
      :type => "JOINING_NETWORK_RELAY",
      :node_id => "#{ARGV[0]}",
      :ip_address => "127.0.0.1"
    }
    sock = UDPSocket.new
    data = JSON.generate(join_message)
    # data = JSON.generate(network_message)
    sock.send(data, 0, ARGV[1]||'localhost', 8767)
    @request = Thread.new do
    #   @server.puts(JSON.generate(join_message))
    #   loop {
    #      @server.puts($stdin.gets.chomp)
    #   }
    end
  end
end

# server = TCPSocket.open("localhost",ARGV[1]||8767)
Client.new()
