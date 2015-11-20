require_relative "./hash.rb"
class Client
	attr_accessor :client_name,:client_id
	def initialize(name)
		@client_name = name
		@client_id = CustomHash.hash(@client_name)	
	end
end
