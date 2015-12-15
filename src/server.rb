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
    # Each routing table conatains the host node
    @routing_table[@guid] = {
        :node_id => @guid,
        :ip_address => @ip
    }
    @udp_server = UDPSocket.new
    @udp_server.bind(@ip,@port)
    recieve_message
    send_message
    ping_table
  end

  def recieve_message
    Thread.new do
      loop{
        data,_ = @udp_server.recvfrom(1024)
        puts "From client #{data}"
        parsed_data = JSON.parse(data)
        case parsed_data["type"]
        when "JOINING_NETWORK"
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
        when "PING"
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

  def notify_network(new_node_data)
    closest_node = @routing_table.keys.min_by { |x| (x.to_f - new_node_data["node_id"].to_f).abs }
    p closest_node
    if closest_node == @guid
      udp_send(Messanger.generate_message("JOINING_NETWORK_RELAY",
        {:node_id => new_node_data["node_id"]},
        @guid),@routing_table[closest_node][:ip_address])
      puts "This is the closest node"
    # else
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
            message  = Messanger.generate_message(arguments[0],{
              :target_id => CustomHash.hash(tag[1..-1]),
              :tag => tag,
              :text => arguments[2]
            },@guid)
            puts "CHAT #{message}"
            # Convert to JSON and send as a UDP to the numerically closest node
          end
        when "CHAT_RETRIEVE"
          arguments[2] = arguments[2].downcase
          message = Messanger.generate_message(arguments[0],{
              :tag => arguments[2],
              :node_id => CustomHash.hash(arguments[2])
          },@guid)
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

  def ping_table
    Thread.new do
      loop{
        sleep(10.miuntes)
        @routing_table.each do |key,route|
          unless key == @guid
            route.merge!({
              :sender_ip => @ip
            })
            data = Messanger.generate_message("PING",route,@guid)
            puts "route #{route}"
            udp_send(data,route[:ip_address])
            @are_pings_ack[route[:node_id]]
            sleep(30)
            if @are_pings_ack[route[:node_id]]
              @are_pings_ack[route[:node_id]] = false
              puts "Acknowldged!!!"
            else
              puts "The node is dead long live the node :("
              @routing_table.delete(route[:node_id])
            end
          end
        end
      }
    end
  end

  def udp_send(data, ip_address)
    puts ">-- Sending data to #{ip_address} --> #{data}"
    sock = UDPSocket.new
    sock.send(data, 0, ip_address, 8767)
    sock.close
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
