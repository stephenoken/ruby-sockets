require "socket"
require "optparse"
require "json"
require_relative "./../bin/pool.rb"
require_relative "./chatroom.rb"
require_relative "./chat_client.rb"
require_relative "./hash.rb"

# Commandline options
options = {
  :guid => 0,
  :ip => "localhost",
  :id => 0
}
OptionParser.new do |opts|
  opts.banner = "Usage: server.rb [options]"
  opts.on("-b","--boot guid","Set Guid") do |guid|
    options[:guid] = guid
    puts "Your guid: #{guid}"
  end
  opts.on("-bs","--bootstrap ip","Set Target IP Address") do |ip|
    options[:ip] = ip
    puts "Target IP address: #{ip}"
  end
  opts.on("-id","--id id","Set Target ID Address") do |id|
    options[:id] = id
    puts "Target ID: #{id}"
  end
  opts.on('-h', '--help', 'Displays Help') do
		puts opts
		exit
	end
end.parse!

class Server
  def initialize(ip,port,guid)
    @ip = ip
    @port = port
    @server = TCPServer.open(@ip,@port)
  	@pool = Thread.pool(12) # By set the number of connections that are accepted
    @connections = Array.new
    @studentID = ARGV[2]
    @chatrooms = Hash.new
    @guid = guid
    @routing_table = Hash.new
  end

  def run
    puts "Server running on : #{@ip}:#{@port}"
    loop{
      Thread.start(@server.accept) do |client|
        @pool.process{
          @connections.push(client)
          peer_2_peer_connection(client)
         }
      end
    }
  end

  def peer_2_peer_connection(client)
    client_input = parse_client_input(client)
    @routing_table[client_input["node_id"]] = {
      :node_id => client_input["node_id"],
      :ip_address => client_input["ip_address"]
    }
    puts @routing_table
    client.puts JSON.generate(message_generation("ROUTING_INFO",client_input))
  end
  def message_generation(message_type, input)
    base_message = {
      :type => message_type,
      :node_id => "#{@guid}"
    }
    case message_type
    when "JOINING_NETWORK"
      base_message.merge!({
        :ip_address => "#{@ip}"
      })
    when "ROUTING_INFO"
      base_message.merge!({
        :node_id => input["node_id"],
        :ip_address => "#{@ip}",
        :route_table => @routing_table.values
      })
    end
    return base_message
  end

  def parse_client_input(client)
    client_input_json = client.gets.chomp.to_s
    puts "<-- Client Input --> #{client_input_json}"
    return JSON.parse(client_input_json)
  end
# Lab 3

  def broadcast_msg_to_room(room_ref, msg)
    @chatrooms[room_ref].clients.each do |_key,c|
      puts "#{_key}--> Broadcasting message:"
      c.thread.puts msg
    end
  end
end

server = Server.new(ARGV[0]||'localhost', ARGV[1]||8767, options[:guid])
server.run()
