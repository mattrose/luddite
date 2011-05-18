require "rubygems"
require "twitter"
require 'highline/import'
require 'yaml'

since_id = nil
CONSUMER_KEY = "f8ZLLDDCHXfq7zw04JwpDA"
CONSUMER_SECRET = "GPe5jNFPJC6vahuYnZ7tei1LbuPJwv9RljBnsAIEEs"

def authorize
  require 'twitter_oauth'
  confirm = ask( "This will wipe out your history, are you sure you want to authorize a new account?",["y","Y","n","N"] ) { |q| q .readline }
  if confirm == "n" or confirm == "N"
    exit 1
  end
  begin
    client = TwitterOAuth::Client.new(
      :consumer_key => CONSUMER_KEY,
      :consumer_secret => CONSUMER_SECRET
    )
  rescue Exception => e
        puts "Couldn't get request_token, double-check yr credentials"
        exit 1
  end
  request_token = client.request_token
  p request_token
  auth = request_token.authorize_url
  puts "Please go to #{auth} to get a PIN, and enter it here"
  #`gnome-open #{auth}`
  pin = ask("enter PIN: ")

  access_token = client.authorize(
    request_token.token,
    request_token.secret,
    :oauth_verifier => pin
  )
  oauth_token = access_token.params[:oauth_token]
  oauth_token_secret = access_token.params[:oauth_token_secret]
  open("#{ENV['HOME']}/.luddite",'w') { |f| f.write({ "token" => oauth_token, "secret" => oauth_token_secret}.to_yaml) }
  exit
end

unless File.exists?("#{ENV['HOME']}/.luddite")
  authorize
  #since_id = nil
  #cf = "#{ENV['HOME']}/.twitcmd"
  #cfs = "#{ENV['HOME']}/.twitcmd_since"
  #eval(open(cf).read)
  #since_id = open(cfs).read.to_i
else
  lconfig = YAML.load_file("#{ENV['HOME']}/.luddite")
  oauth_token = lconfig["token"]
  oauth_token_secret = lconfig["secret"]
  if lconfig["since"]
    since_id = lconfig["since"]
  end
end
def authorize
  confirm = ask( "This will wipe out your history, are you sure you want to authorize a new account?",["y","Y","n","N"] ) { |q| q .readline } 
  if confirm == "n" or confirm == "N"
    exit 1
  end
  begin 
    client = TwitterOAuth::Client.new(
      :consumer_key => CONSUMER_KEY,
      :consumer_secret => CONSUMER_SECRET
    )
  rescue Exception => e
  	puts "Couldn't get request_token, double-check yr credentials"
  	exit 1
  end
  request_token = client.request_token
  p request_token
  auth = request_token.authorize_url
  puts "Please go to #{auth} to get a PIN, and enter it here"
  #`gnome-open #{auth}`
  pin = ask("enter PIN: ")

  access_token = client.authorize(
    request_token.token,
    request_token.secret,
    :oauth_verifier => pin 
  )
  oauth_token = access_token.params[:oauth_token]
  oauth_token_secret = access_token.params[:oauth_token_secret]  
  open("#{ENV['HOME']}/.luddite",'w') { |f| f.write({ "token" => oauth_token, "secret" => oauth_token_secret}.to_yaml) }
  exit
end
# Certain methods require authentication. To get your Twitter OAuth credentials,
# register an app at http://dev.twitter.com/apps
Twitter.configure do |config|
  config.consumer_key = CONSUMER_KEY
  config.consumer_secret = CONSUMER_SECRET
  config.oauth_token = oauth_token
  config.oauth_token_secret = oauth_token_secret
end

# Initialize your Twitter client
client = Twitter::Client.new

def get_reply_chain(status)
        a = ""
        depth = 1
        while status
                begin

                        tweet = Twitter.status(Twitter.status(status).in_reply_to_status_id)
                        depth_i = ""
                        depth.times { depth_i << ">>" }
                        a << "#{depth_i} #{tweet.user.name} #{tweet.text}\n"
                        status = Twitter.status(status).in_reply_to_status_id
                rescue Exception => e
                        status = nil
                end
                depth += 1
        end
        return a
end


if since_id
	msgs = []
	max_id = nil
	last_max_id = 0
### Collect all messages since the last since_id.  Twitter only gives you 200 at a time, so cycle
#### throught the pages.
	while max_id != last_max_id do
		if max_id
			tmsgs = client.home_timeline(:count => 200, :since_id => since_id, :max_id => max_id)
			tmsgs.delete_at(-1)
			last_max_id = tmsgs.last.id
		else
			tmsgs = client.home_timeline(:count => 200, :since_id => since_id)
			last_max_id = 0
    end
    max_id = tmsgs.last.id
    msgs.concat(tmsgs)
    ### Delete an artefact of the collection process
		msgs.delete_at(-1)
	end
else
	msgs = client.home_timeline(:count => 1)
end	

### If the array of messages is empty, we don't need to continue
if msgs == []
        puts "no new messages"
        exit
end

### Delete an artefact of the collection process
puts "#{msgs.length} new message since last time this was run"
if since_id
puts "the last message you read was from #{Twitter.status(since_id.to_i).created_at}"
end
puts "<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>"
new_since = msgs.first.id
num = msgs.length
### Loop through the messages
msgs.reverse.each_with_index { |a,i| 
	puts "message #{i + 1} of #{num}"
	puts a.user.name 
	puts a.text 
	puts "http://twitter.com/#!/#{a.user.screen_name}/status/#{a.id}" 
	if a.retweeted_status
		puts "RETWEETED from #{a.retweeted_status.user.name}"
		puts a.retweeted_status.text
	end
	if a.in_reply_to_status_id 
		puts "in reply to"
		puts get_reply_chain(a.id)
	end
	puts a.created_at
	puts "---------------------------------------------------------------"
	cmd = ask("reply r, retweet rt, Old style RT ro, next n or quit q:  ", ["","r","rt","ro""n","q"]) { |q| q.readline }
	if cmd == "q"
		new_since = a.id
		break
	elsif cmd == "n" or cmd == ""
		next
	elsif cmd == "r"
	  reply = ask("enter reply: @#{a.user.screen_name} ") { |q| q.readline }
	  Twitter.update(reply, {:in_reply_to_status_id => a.id})
	elsif cmd == "rt"
	  rt = Twitter.retweet(a.id)
	elsif cmd == "ro"
	  text = ask("RT @#{a.user.screen_name} #{a.text}")
	end
}

lconfig["since"] = new_since
p lconfig
open("#{ENV['HOME']}/.luddite",'w') { |f| f.write(lconfig.to_yaml) }
# Get your rate limit status
puts client.rate_limit_status.remaining_hits.to_s + " Twitter API request(s) remaining this hour"
