require "socket"

class Server
  def initialize(ip,port)
    @ip = ip
    @port = port
    @server = TCPServer.open(@ip,@port)
    @connections = {}
  end

  def run
    puts "Server running on port: #{@port}"
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
        clientInput = client.gets.chomp.to_s
        command = "#{clientInput.partition(" ").first}"
        # clientInput = "#{clientInput.partition(" ").last}"
        case command
        when "KILL_SERVICE"
          kill_service(client)
        when "HELO"
          hello_message(client, clientInput)
        end
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
