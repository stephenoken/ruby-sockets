require "socket"
require_relative "./../bin/pool.rb"
require_relative "./chatroom.rb"
require_relative "./chat_client.rb"

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
    chatroom_ref = 0
		join_id = 0
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
				chatroom = chatroom_join(arguments[2],client) 
				chatroom_ref = chatroom.chatroom_id
			when "CLIENT_NAME"
				register_client(arguments[2], chatroom_ref, join_id, client)
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

	def chatroom_join(message, client)
		chatroom = Chatroom.new(message)
		if @chatrooms[chatroom.chatroom_id].nil?
			@chatrooms[chatroom.chatroom_id] = chatroom 
		else
			chatroom = @chatrooms[chatroom.chatroom_id]
		end
		puts chatroom.chatroom_id
		client.puts "JOINED_CHATROOM:#{message}\nSERVER_IP:#{@ip}\nPORT:#{@port}\nROOM_REF:#{chatroom.chatroom_id}"
		return chatroom
	end

	def register_client(message, chatroom_ref, join_id, client)
		c_client = Client.new(message)
		puts "Client : #{c_client.client_name} #{c_client.client_id}"
		join_id = @chatrooms[chatroom_ref].join_room(c_client)
		client.puts "JOIN_ID:#{join_id}"
		chatroom_session(client,c_client,chatroom_ref)
	end

	def chatroom_session(client, c_client, chatroom_ref)
		client.puts "CHAT:#{chatroom_ref}\nCLIENT_NAME:#{c_client.client_name}"
	end
end

server = Server.new(ARGV[0]||'localhost',ARGV[1]||2000)
server.run()
