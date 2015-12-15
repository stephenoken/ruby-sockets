require "json"
class Messanger
	def self.generate_message(message_type, input)
    base_message = {
      :type => message_type,
      :node_id => "#{@guid}"
    }
    case message_type
    when "JOINING_NETWORK"
      base_message.merge!({
        :ip_address => input[:ip_address]
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
    when "PING"
      base_message.merge!({
        :target_id => input[:node_id],
        :sender_id => base_message.delete(:node_id),
        :ip_address => "#{@ip}"
      })
    when "ACK"
      base_message.merge!({
        :node_id => input[:node_id],
        :ip_address => input[:ip_address]
      })
    end
    return JSON.generate(base_message)
	end
end
