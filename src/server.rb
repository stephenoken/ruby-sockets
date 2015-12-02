require "socket"
require_relative "./../bin/pool.rb"
require_relative "./chatroom.rb"
require_relative "./chat_client.rb"
require_relative "./hash.rb"

class Server
  def initialize(ip,port)
    @ip = ip
    @port = port
    @server = TCPServer.open(@ip,@port)
  	@pool = Thread.pool(12) # By set the number of connections that are accepted
    @connections = Array.new
    @studentID = ARGV[2]
    @chatrooms = Hash.new
  end

  def run
    puts "Server running on : #{@ip}:#{@port}"
    loop{
      Thread.start(@server.accept) do |client|
        @pool.process{
          @connections.push(client)
          client_connection(client)
         }
      end
    }
  end

  def client_connection(client)
    room_ref = ""
		loop{
      arguments = get_client_arguments(client)
      command = arguments[0]
      case command
      when "KILL_SERVICE"
        kill_service(client)
      when "HELO"
        hello_message(client, arguments[2])
      when "JOIN_CHATROOM"
				room_ref = join_chatroom(arguments[2],client)
      when "CLIENT_NAME"
        register_client(arguments[2], room_ref, client)
      when "LEAVE_CHATROOM"
        leave_chatroom(arguments[2], client)
      when "CHAT"
        chatroom_session(arguments[2],client)
      when "DISCONNECT"
        client_disconnect(client)
			else
        # client.puts "Invalid Command"
      end
    }
  end

  def kill_service(client)
    # @connections.each do |socket|
    #   socket.close
    # end
    client.close
    @server.close
    puts "Goodbye"
  end

  def hello_message(client, input)
    client.puts "HELO #{input}\nIP:#{@ip}\nPort:#{@port}\nStudentID:#{@studentID}"
  end

	def join_chatroom(chatroom_name, client)
		chatroom = Chatroom.new(chatroom_name)
		if @chatrooms[chatroom.chatroom_id].nil?
      @chatrooms[chatroom.chatroom_id] = chatroom
		else
      puts "Chatroom Exists"
			chatroom = @chatrooms[chatroom.chatroom_id]
		end
		puts "Chatroom id: #{chatroom.chatroom_id}"
		client.puts "JOINED_CHATROOM:#{chatroom_name}\nSERVER_IP:#{@ip}\nPORT:#{@port}\nROOM_REF:#{chatroom.chatroom_id}"
    return chatroom.chatroom_id
	end

	def register_client(client_name, room_ref, client)
    puts room_ref
		c_client = Client.new(client_name,client)
    join_msg = "CHAT:#{room_ref}\nCLIENT_NAME:#{c_client.client_name}\nMESSAGE:#{c_client.client_name} has joined this chatroom.\n\n"
		puts "Client : #{c_client.client_name} #{c_client.client_id}"
		join_id = @chatrooms[room_ref].join_room(c_client) #Pass the client thread as well
    client.puts "JOIN_ID:#{join_id}"
    # client.puts join_msg
    broadcast_msg_to_room(room_ref,join_msg)
	end

	def leave_chatroom(room_ref, client)
    puts "Leave Chatroom #{room_ref}"
    loop {
      arguments = get_client_arguments(client)
      case arguments[0]
      when "JOIN_ID"
        puts "Clients name:#{@chatrooms[room_ref].clients[arguments[2]].client_name}"
        @chatrooms[room_ref].clients.delete(arguments[2])
        puts "Deleted Client:#{@chatrooms[room_ref].clients}"
        client.puts "LEFT_CHATROOM:#{room_ref}\nJOIN_ID:#{arguments[2]}"
      when "CLIENT_NAME"
        leave_msg  = "CHAT:#{room_ref}\nCLIENT_NAME:#{arguments[2]}\nMESSAGE:#{arguments[2]} has left this chatroom.\n\n"
        puts leave_msg
        client.puts leave_msg
        broadcast_msg_to_room(room_ref,leave_msg)
        break
      end
    }
	end

  def chatroom_session(room_ref,client)
    client_name = ""
    puts "In chatroom_session"
    loop {
      arguments = get_client_arguments(client)
      case arguments[0]
      when "JOIN_ID"
        # join_id = arguments[2]
        # Insert error handlers
      when "CLIENT_NAME"
        puts arguments[2]
        client_name = arguments[2]
      when "MESSAGE"
        puts arguments[2]
        message = "CHAT:#{room_ref}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{arguments[2]}\n\n"
        broadcast_msg_to_room(room_ref,message)
        break
      end
    }
  end

	def client_disconnect(client)
		puts "In client_disconnect"
		loop {
			arguments = get_client_arguments(client)
			case arguments[0]
			when "CLIENT_NAME"
				id = CustomHash.hash(arguments[2])
				puts id
        puts "Chatrooms #{@chatrooms}"
        @chatrooms.each do |key, chatroom|
          unless chatroom.clients.include?(id)
            #Skip over rooms that client is not a member of
            break
          end
          puts "The key is #{key}"
          message = "CHAT:#{key}\nCLIENT_NAME:#{arguments[2]}\nMESSAGE:#{arguments[2]} has left this chatroom.\n\n"
          puts "Disconnect message: #{message}"
          broadcast_msg_to_room(key,message)
          chatroom.clients.delete(id)
        end
        puts "Client Closed"
        client.close
        break
			end
		}
	end

  def get_client_arguments(client)
    clientInput = client.gets.chomp.to_s
    puts "<-- Client Input --> #{clientInput}"
    arguments = Array.new
    if clientInput.include? ":"
      arguments = clientInput.partition(":")
    else
      arguments = clientInput.partition(" ")
    end
    arguments[2] = arguments[2].lstrip
    return arguments
  end

  def broadcast_msg_to_room(room_ref, msg)
    @chatrooms[room_ref].clients.each do |_key,c|
      puts "#{_key}--> Broadcasting message:"
      c.thread.puts msg
    end
  end
end

server = Server.new(ARGV[0]||'localhost',ARGV[1]||2000)
server.run()
