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
    @chatrooms = Array.new
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
    client.puts "JOINED_CHATROOM:room1\nSERVER_IP:#{@ip}\nPORT:#{@port}"
    loop{
      clientInput = client.gets.chomp.to_s
      puts clientInput
      arguments = clientInput.partition(" ")
      command = "#{arguments.first}"
      case command
      when "KILL_SERVICE"
        kill_service(client)
      when "HELO"
        hello_message(client, clientInput)
      when "JOIN_CHATROOM"
        puts "#{arguments.last}"
        #@chatrooms.push(Chatroom.new(arguments.last))
        #client.puts "JOINED_CHATROOM:#{@chatrooms[0].name}\nSERVER_IP:#{@ip}\nPORT:#{@port}"
      else
        # client.puts "Invalid Command"
      end
    }
  end

  def kill_service(client)
    @connections.each { |c| c.close}
    @server.close
  end

  def hello_message(client, input)
    client.puts "#{input}\nIP:#{@ip}\nPort:#{@port}\nStudentID:#{@studentID}"
  end

  def chatroom_response(client, chatroom)
    client.puts "JOINED_CHATROOM:#{chatroom.name}\nSERVER_IP:#{@ip}\nPort:#{@port}"
  end
end

server = Server.new(ARGV[0]||'localhost',ARGV[1]||2000)
server.run()
