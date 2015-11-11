require "socket"
require_relative "./../bin/pool.rb"


class Server
  def initialize(ip,port)
    @ip = ip
    @port = port
    @server = TCPServer.open(@ip,@port)
  	 @pool = Thread.pool(2) # By set the number of connections that are accepted
    @connections = Array.new
    @studentID = ARGV[2]
  end

  def run
    puts "Server running on : #{@ip}:#{@port}"
    loop{
      Thread.start(@server.accept) do |client|
        @connections.push(client)
        @pool.process{
          client_connection(client)
        }
      end
    }
  end

  def client_connection(client)
    loop{
      clientInput = client.gets.chomp.to_s
      puts clientInput
      command = "#{clientInput.partition(" ").first}"
      case command
      when "KILL_SERVICE"
        kill_service(client)
      when "HELO"
        hello_message(client, clientInput)
      else
        # client.puts "Invalid Command"
      end
    }
  end

  def kill_service(client)
		Thread.kill self
		abort
    #@connections.each { |c| c.close}
    #@server.close
  end

  def hello_message(client, input)
    client.puts "#{input}\nIP:#{@ip}\nPort:#{@port}\nStudentID:#{@studentID}"
  end
end

server = Server.new(ARGV[0]||'localhost',ARGV[1]||2000)
server.run()
