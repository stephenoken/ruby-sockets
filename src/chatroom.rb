class Chatroom
	attr_accessor :chatroom_name, :chatroom_id
	def initialize(name)
		@chatroom_name = name
		@clients = Array.new
		@chatroom_id = join_room(@chatroom_name)
	end

	def join_room(room_name)
		hash = 0
		for i in 0..room_name.length - 1
			hash = hash * 31 + room_name[i].ord
			#Had to convert the character to an integer
		end 
		return hash.abs
	end 
end

