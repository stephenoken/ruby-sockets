# ruby-sockets
## Installation
1. Be sure to have `ruby verison 2.x` installed.
2. `cd` into this repo 
3. Run `sh start.sh` The script will launch a server on its default port number `2000`
4. In a new terminal session run `ruby client.rb`
5. You can pass a port number as an argument for both scripts

## CS705
For both Lab 2 and Lab 3, be sure to use the master branch

## Personal Project 
To run the peer-2-peer programme: 

1. Checkout the `peer-2-peer` branch.
2. Run the following command `ruby src/server.rb [loacal machine's ip address] [options]`. To view the options run `ruby src/server.rb --help` 
3. To send a chat message type `CHAT [message]`.
4. To retrieve chate messages type `CHAT_RETRIEVE [tag]`
5. Ping messages only occur when the sender doesn't recieve any ACK message from the destination.

Note: I've placed a fair amount of tracer statements that I didn't get around to removing. 
