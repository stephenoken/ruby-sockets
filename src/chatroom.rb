require_relative "./hash.rb"
class Chatroom
	attr_accessor :chatroom_name, :chatroom_id, :clients
	def initialize(name)
		@chatroom_name = name
		@clients = Hash.new
		@chatroom_id = CustomHash.hash(@chatroom_name)
	end

	def join_room(client)
		if @clients[client.client_id].nil?
			@clients[client.client_id] = client
			puts "#{@chatroom_name}: #{client.client_name} has joined the room"
			return client.client_id
		else
			puts "#{client.client_name} has already been taken"
		end
	end
end
