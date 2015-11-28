require_relative "./hash.rb"
class Client
	attr_accessor :client_name,:client_id, :thread
	def initialize(name, thread)
		@client_name = name
		@client_id = CustomHash.hash(@client_name)
		@thread = thread
	end
end
