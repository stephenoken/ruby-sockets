require "socket"
require "thread/pool"


class Server
  def initialize(ip,port)
    @ip = ip
    @port = port
    @server = TCPServer.open(@ip,@port)
    @connections = []
    @pool = Thread.pool(1) # By defualt pooling is set 1 for testing purposes
  end

  def run
    puts "Server running on port: #{@port}"
    loop{
      Thread.start(@server.accept) do |client|
        @pool.process{
          client.puts(Time.now.ctime)
          client_connection(client)
        }
      end
    }
  end
# Add a new method that listens for client input

  def client_connection(client)
    loop{
      clientInput = client.gets.chomp.to_s
      command = "#{clientInput.partition(" ").first}"
      case command
      when "KILL_SERVICE"
        kill_service(client)
      when "HELO"
        hello_message(client, clientInput)
      else
        client.puts "Invalid Command"
      end
    }
  end
  def kill_service(client)
    client.puts "Goodbye..."
    client.close
  end

  def hello_message(client, input)
    client.puts "#{input}\nIP:[#{@ip}]\nPORT:[#{@port}]"
  end
end

server = Server.new('localhost',ARGV[0]||2000)
server.run()
