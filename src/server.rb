require "socket"
require "optparse"
require "json"
require_relative "./hash.rb"
require_relative "./peer-2-peer/messanger.rb"

# This is super important for finding the numerically closest value to the guid
# numbers = ["1","6","7","10","2"]
# p numbers.min_by { |x| (x.to_f - 5).abs }
# p numbers.min(4){|a,b| (a.to_f <=> b.to_f).abs}

# Commandline options
options = {
  :guid => 0,
  :ip => "localhost",
  :id => 0,
  :regular_node => true
}
OptionParser.new do |opts|
  opts.banner = "Usage: server.rb [options]"
  opts.on("-b","--boot guid","Set Guid") do |guid|
    options[:guid] = guid
    options[:regular_node] = false
    puts "Your guid: #{guid}"
  end
  opts.on("-bs","--bootstrap ip","Set Target IP Address") do |ip|
    options[:ip] = ip
    puts "Target IP address: #{ip}"
  end
  opts.on("-id","--id id","Set ID") do |id|
    options[:guid] = id
    puts "Set ID: #{id}"
  end
  opts.on('-h', '--help', 'Displays Help') do
		puts opts
		exit
	end
end.parse!

def join_network(server,is_regular_node,guid,target_ip)
  if is_regular_node
    server.udp_send(Messanger.generate_message("JOINING_NETWORK",
    {
      :ip_address => ARGV[0]
    },guid),target_ip)
    puts "you aren't the node"
  else
    puts "You are the node"
  end
end
class Server
  def initialize(ip,port,guid)
    @ip = ip
    @port = port
    @guid = guid
    @routing_table = Hash.new
    @are_pings_ack = Hash.new(false)
    @hashtags = Hash.new({
        :response => Array.new
    })
    # Each routing table conatains the host node
    @routing_table[@guid] = {
        :node_id => @guid,
        :ip_address => @ip
    }
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
        parsed_data = JSON.parse(data)
        case parsed_data["type"]
        when "JOINING_NETWORK_RELAY"
          puts "In notify_network"
          notify_network(parsed_data)
          send_routing_table(parsed_data)
        when "JOINING_NETWORK"
          send_routing_table(parsed_data)
        when "ROUTING_INFO"
          parsed_data["route_table"].each  do |route|
            puts "Route #{route}"
            @routing_table[route["node_id"]] = {
              :node_id => route["node_id"],
              :ip_address => route["ip_address"]
            }
          end
          puts "Routing table  #{@routing_table}"
				when "LEAVE_NETWORK"
					puts @routing_table.delete(parsed_data["node_id"])
          puts "Routing table  #{@routing_table}"
        when "CHAT"
          process_message(parsed_data,"target_id")
        when "CHAT_RETRIEVE"
          process_message(parsed_data,"node_id")
        when "PING"
          process_message(parsed_data,"target_id")
          message = Messanger.generate_message("ACK",{
              :node_id => parsed_data["target_id"],
              :ip_address => @ip
          },@guid)
          puts "ACK response: #{message}"
          udp_send(message,parsed_data["ip_address"])
        when "ACK"
          @are_pings_ack[parsed_data["node_id"]] = true
        end
      }
    end
  end

  def process_message(parsed_data,key)
    if get_nearest_node(parsed_data[key]) == @guid
      puts "It has arrived at the destination"
      case parsed_data["type"]
      when "CHAT"
        process_chat(parsed_data)
      when "CHAT_RETRIEVE"
        process_chat_retrieve(parsed_data)
      when "PING"
        puts "Work in prgress"
        process_ping(parsed_data)
      end
    else
      hop_message(parsed_data,key)
    end
  end

  def process_ping(parsed_data)

  end

  def process_chat_retrieve(parsed_data)
    puts "Parsed --> #{parsed_data}"
    puts "Messages --> #{@hashtags[CustomHash.hash(parsed_data["tag"])]}"
    hash_chat_resp = {
      :node_id => parsed_data["sender_id"],
      :tag => parsed_data["tag"],
      :response => @hashtags[CustomHash.hash(parsed_data["tag"])][:response]
    }
    chat_resp = Messanger.generate_message("CHAT_RESPONSE",hash_chat_resp,@guid)
    puts "Chat response #{chat_resp}"
    udp_send(chat_resp,@routing_table[get_nearest_node(hash_chat_resp[:node_id])][:ip_address])
  end

  def process_chat(parsed_data)
    if @hashtags[CustomHash.hash(parsed_data["tag"])].empty?
      @hashtags[CustomHash.hash(parsed_data["tag"])] = {
        :tag => parsed_data["tag"],
        :response => @hashtags[CustomHash.hash(parsed_data["tag"])][:response].push({:text => parsed_data["text"]})
      }
    else
      @hashtags[CustomHash.hash(parsed_data["tag"])].merge!({
        :response => @hashtags[CustomHash.hash(parsed_data["tag"])][:response].push({:text => parsed_data["text"]})
      })
    end
    ack_msg = {
    :node_id => parsed_data["sender_id"],
    :tag => parsed_data["tag"]
    }
    chat_ack = Messanger.generate_message("CHAT_ACK",ack_msg, @guid)
    puts "CHAT_ACK --> #{chat_ack}"
    puts  "Hashtags --> #{@hashtags}"
    udp_send(chat_ack,@routing_table[get_nearest_node(ack_msg[:node_id])][:ip_address])
  end

  def hop_message(parsed_data,key)
    puts "The search continues..."
    if parsed_data["type"] == "PING"
      parsed_data["ip_address"] = @ip
    end
    udp_send(JSON.generate(parsed_data),@routing_table[get_nearest_node(parsed_data[key])][:ip_address])
  end
  def send_routing_table(parsed_data)
    notify_network(parsed_data)
    @routing_table[parsed_data["node_id"]] = {
      :node_id => parsed_data["node_id"],
      :ip_address => parsed_data["ip_address"]
    }
    parsed_data.merge!({
        "gateway_ip" => "#{@ip}",
        "routes" => @routing_table.values
    })
    udp_send(Messanger.generate_message("ROUTING_INFO",parsed_data,@guid),
    parsed_data["ip_address"])
  end

  def notify_network(new_node_data)
    puts "node data #{new_node_data}"
    closest_node = get_nearest_node(new_node_data["node_id"])
    if closest_node == @guid
      puts "This is the closest node"
    else
      puts "The closest node #{closest_node}"
      udp_send(Messanger.generate_message("JOINING_NETWORK_RELAY",
      {:node_id => new_node_data["node_id"]},
      @guid),@routing_table[closest_node][:ip_address])
    end
  end

  def get_nearest_node(node_id)
    return @routing_table.keys.min_by { |x| (x.to_f - node_id.to_f).abs }
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
            message = {
              :target_id => CustomHash.hash(tag[1..-1]),
              :tag => tag[1..-1],
              :text => arguments[2]
            }
            data  = Messanger.generate_message(arguments[0],message,@guid)
            puts "CHAT #{data}"
            closest_node = get_nearest_node(message[:target_id])
            puts "The closest to send the message node #{closest_node}"
            udp_send(data,@routing_table[closest_node][:ip_address])
            ping_mode(message[:target_id])
          end
        when "CHAT_RETRIEVE"
          arguments[2] = arguments[2].downcase
          message = {
              :tag => arguments[2],
              :node_id => CustomHash.hash(arguments[2])
          }
          data = Messanger.generate_message(arguments[0],message,@guid)
          udp_send(data,@routing_table[get_nearest_node(message[:node_id])][:ip_address])
          puts "CHAT_RETRIEVE #{data}"
				when "LEAVE_NETWORK"
					@routing_table.each do |_,route|
						puts "Route ip_address: #{route[:ip_address]}"
						udp_send(Messanger.generate_message("LEAVE_NETWORK",nil,@guid),route[:ip_address])
					end
        end
      }
    end
  end

  def ping_mode(suspect_node)
    Thread.new{
      sleep 5
      puts "No Acknowldgement :("
      route = @routing_table[get_nearest_node(suspect_node)]
      if route[:node_id] = @guid
        route.merge!({:node_id => suspect_node,:sender_ip => @ip})
        data = Messanger.generate_message("PING",route,@guid)
        puts data
        udp_send(data, route[:ip_address])
        unless @are_pings_ack[suspect_node]
          puts "The node is dead"
        end
      end
    }
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

  def udp_send(data, ip_address)
    puts ">-- Sending data to #{ip_address} --> #{data}"
		if ip_address == nil
			puts "The ip address is empty now hopping message to nearest node"
		end
    sock = UDPSocket.new
    sock.send(data, 0, ip_address, 8767)
    sock.close
    puts "Sent...."
  end
  def run
    puts "Server running on : #{@ip}:#{@port}"
    loop{
    }
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
join_network(server,options[:regular_node],options[:guid],options[:ip])
server.run()
