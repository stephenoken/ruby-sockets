require "socket"
require_relative "./../bin/pool.rb"
require_relative "./chatroom.rb"

class Server
  def initialize(ip,port)
    @ip = ip
    @port = port
    @server = TCPServer.open(@ip,@port)
  	@pool = Thread.pool(2) # By set the number of connections that are accepted
    @connections = Array.new
    @studentID = ARGV[2]
    @chatrooms = Hash.new
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
      arguments = Array.new
			if clientInput.include? ":"
				arguments = clientInput.partition(":")
			else
				arguments = clientInput.partition(" ")
			end
      command = arguments[0]
      case command
      when "KILL_SERVICE"
        kill_service(client)
      when "HELO"
        hello_message(client, clientInput)
      when "JOIN_CHATROOM"
				chatroom = Chatroom.new(arguments[2])
				if @chatrooms[chatroom.chatroom_id].nil?
					puts "Chatroom does not exist"
					@chatrooms[chatroom.chatroom_id] = chatroom 
				else
					puts "Chatroom exists"
					chatroom = @chatrooms[chatroom.chatroom_id]
				end
				puts chatroom.chatroom_id
				puts @chatrooms.keys 
				client.puts "JOINED_CHATROOM:#{arguments[2]}\nSERVER_IP:#{@ip}\nPORT:#{@port}\nROOM_REF:#{chatroom.chatroom_id}"
			when "CLIENT_NAME"

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
