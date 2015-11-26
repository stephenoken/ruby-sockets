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
		loop{
      arguments = get_client_arguments(client)
      command = arguments[0]
      case command
      when "KILL_SERVICE"
        kill_service(client)
      when "HELO"
        hello_message(client, arguments[2])
      when "JOIN_CHATROOM"
				join_chatroom(arguments[2],client)
			else
        # client.puts "Invalid Command"
      end
    }
  end

  def kill_service(client)
    # @connections.each { |c| c.close}
    client.close
    @server.close
  end

  def hello_message(client, input)
    puts input
    client.puts "HELO #{input}\nIP:#{@ip}\nPort:#{@port}\nStudentID:#{@studentID}"
    puts input
  end

	def join_chatroom(message, client)
		chatroom = Chatroom.new(message)
		if @chatrooms[chatroom.chatroom_id].nil?
      @chatrooms[chatroom.chatroom_id] = chatroom
		else
			chatroom = @chatrooms[chatroom.chatroom_id]
		end
		puts "Chatroom id: #{chatroom.chatroom_id}"
		client.puts "JOINED_CHATROOM:#{message}\nSERVER_IP:#{@ip}\nPORT:#{@port}\nROOM_REF:#{chatroom.chatroom_id}"

    loop{
      arguments = get_client_arguments(client)
      command = arguments[0]
      case command
      when "CLIENT_NAME"
        register_client(arguments[2], chatroom, client)
        break
      end
    }
	end

	def register_client(message, chatroom, client)
		c_client = Client.new(message)
		puts "Client : #{c_client.client_name} #{c_client.client_id}"
		join_id = @chatrooms[chatroom.chatroom_id].join_room(c_client) #Pass the client thread as well
		client.puts "JOIN_ID:#{join_id}"
		chatroom_session(client,c_client,chatroom)
	end

	def chatroom_session(client, c_client, chatroom)
		client.puts "CHAT:#{chatroom.chatroom_id}\nCLIENT_NAME:#{c_client.client_name}\nMESSAGE:#{c_client.client_name} has joined this chatroom.\n\n"
		loop {
     arguments = get_client_arguments(client)
     puts "Chat Session: #{arguments}"
		 command = arguments[0]
		 case command
		 when "LEAVE_CHATROOM"
			 leave_chatroom(arguments[2], client)
       break
		 end
    }

	end

	def leave_chatroom(room_ref, client)
    loop {
      join_id_arguments = get_client_arguments(client)
      arguments = get_client_arguments(client)
      if join_id_arguments[0]=="JOIN_ID"
        puts "Leaving Chatroom..."
        puts @chatrooms[room_ref].clients[join_id_arguments[2]].client_name
        @chatrooms[room_ref].clients.delete([join_id_arguments[2]])
        puts "Deleted Client:#{@chatrooms[room_ref].clients}"
        client.puts "LEFT_CHATROOM:#{room_ref}\nJOIN_ID:#{join_id_arguments[2]}"
      end
    }
	end
  def get_client_arguments(client)
    clientInput = client.gets.chomp.to_s
    puts clientInput
    arguments = Array.new
    if clientInput.include? ":"
      arguments = clientInput.partition(":")
    else
      arguments = clientInput.partition(" ")
    end
    return arguments
  end
end

server = Server.new(ARGV[0]||'localhost',ARGV[1]||2000)
server.run()
