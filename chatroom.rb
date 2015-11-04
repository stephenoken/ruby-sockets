class Chatroom
  attr_reader :name
  
  def initialize(name)
    @name = name
    @clients = Array.new
  end

  def joinChatroom(client)
    @clients.push(client)
  end

  def showChatters
    return @clients
  end
end
