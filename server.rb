require "socket"

class Server
  def initialize(ip,port)
    @server = TCPServer.open(ip,port)
    @connections = {}
  end

  def run
    loop{
      Thread.start(@server.accept) do |client|
        client.puts(Time.now.ctime)
        #  nick_name = client.gets.chomp.to_s
        #  puts nick_name.is_a?(String)
        #  puts nick_name
        #  if nick_name == "Connected"
        #    puts "Foo"
        #    client.puts "Welcome #{nick_name}"
        #  end
        #  @connections.add(client)
        case client.gets.chomp.to_s
        when "KILL_SERVICE"
            client.puts "Service Terminated"
        end
      end
    }
  end
end

server = Server.new('localhost',2000)
server.run()
