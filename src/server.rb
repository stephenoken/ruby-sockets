require "socket"
require "optparse"
require "json"
require_relative "./../bin/pool.rb"
require_relative "./chatroom.rb"
require_relative "./chat_client.rb"
require_relative "./hash.rb"

# This is super important for finding the numerically closest value to the guid
# numbers = ["1","6","7","10","2"]
# p numbers.min_by { |x| (x.to_f - 5).abs }

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
    @udp_server = UDPSocket.new
    @udp_server.bind(@ip,@port)
    recieve_message
    send_message
  end

  def recieve_message
    Thread.new do
      loop{
        data,_ = @udp_server.recvfrom(1024)
        puts "From client #{data}"
      }
    end
  end

  def send_message
    Thread.new do
      loop{
        puts "Enter command"
        command = $stdin.gets.chomp
        arguments = get_client_arguments(command)
        case arguments[0]
        when "CHAT"
          get_tags(arguments[2].split(' ')).each do |tag|
            message  = JSON.generate(message_generation(arguments[0],{
              :target_id => CustomHash.hash(tag[1..-1]),
              :tag => tag,
              :text => arguments[2]
            }))
            puts "CHAT #{message}"
            # Convert to JSON and send as a UDP to the numerically closest node
          end
        when "CHAT_RETRIEVE"
          message = JSON.generate(message_generation(arguments[0],{
              :tag => arguments[2],
              :node_id => CustomHash.hash(arguments[2])
          }))
          puts "CHAT_RETRIEVE #{message}"
        end
      }
    end
  end

  def get_tags(words)
    tags = []
    words.each do |word|
      if word[0] == "#"
        tags.push(word.downcase)
      end
    end
    return tags
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
    client.close
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
    when "JOINING_NETWORK_RELAY"
      base_message.merge!({
        :gateway_id => input["node_id"]
      })
    when "CHAT"
      base_message.merge!({
          :target_id => input[:target_id],
          :sender_id => base_message.delete(:node_id),
          :tag => input[:tag],
          :text => input[:text]
      })
    when "CHAT_RETRIEVE"
      base_message.merge!({
          :tag => input[:tag],
          :node_id => input[:node_id],
          :sender_id => base_message.delete(:node_id)
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
  def get_client_arguments(client_input)
    puts "<-- Client Input --> #{client_input}"
    arguments = Array.new
    if client_input.include? ":"
      arguments = client_input.partition(":")
    else
     arguments = client_input.partition(" ")
    end
    arguments[2] = arguments[2].lstrip
    return arguments
  end
end

server = Server.new(ARGV[0]||'localhost', ARGV[1]||8767, options[:guid])
server.run()
