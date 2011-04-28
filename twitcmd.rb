require "rubygems"
require "twitter"
require 'highline/import'

post = nil
count = 200

if ARGV[0] == "post"
	post = ARGV[1..-1]
end
since_id = nil
cf = "#{ENV['HOME']}/.twitcmd"
cfs = "#{ENV['HOME']}/.twitcmd_since"
if File.exists?(cf)
	eval(open(cf).read)
	if CONSUMER_KEY && CONSUMER_SECRET
		puts "consumer key read"
	else
		CONSUMER_KEY = "f8ZLLDDCHXfq7zw04JwpDA"
		CONSUMER_SECRET = "GPe5jNFPJC6vahuYnZ7tei1LbuPJwv9RljBnsAIEEs"
	end
	
else
	puts "no cf file"
	exit
end
if File.exists?(cfs)
        since_id = open(cfs).read.to_i
end

# Certain methods require authentication. To get your Twitter OAuth credentials,
# register an app at http://dev.twitter.com/apps
Twitter.configure do |config|
  config.consumer_key = CONSUMER_KEY
  config.consumer_secret = CONSUMER_SECRET
  config.oauth_token = OAUTH_TOKEN
  config.oauth_token_secret = OAUTH_TOKEN_SECRET
end

# Initialize your Twitter client
client = Twitter::Client.new

# Post a status update
if ARGV.length > 1
	client.update("I just posted a status update via the Twitter Ruby Gem!")
end

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


new_since = client.home_timeline.first.id
args = { :include_entities => 't' } 
args = { :include_entities => 't', :count => 200, :since_id => since_id } if since_id
msgs = []
#msgs = client.home_timeline(args)
max_id = nil
last_max_id = 0
while max_id != last_max_id do 
	if max_id
		tmsgs = client.home_timeline(:count => 200, :since_id => since_id, :max_id => max_id)
		last_max_id = msgs.last.id
	else 
		tmsgs = client.home_timeline(:count => 200, :since_id => since_id)
		last_max_id = 0
	end
	max_id = tmsgs.last.id
	msgs.concat(tmsgs)
end
if msgs == []
        puts "no new messages"
        exit
end

#puts "no more messages"
msgs.delete_at(-1)
num = msgs.length
puts "<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>"
puts "#{msgs.length} new message since last time this was run"
puts "the last message you read was from #{Twitter.status(since_id.to_i).created_at}"

msgs.reverse.each_with_index { |a,i| 
	puts "message #{i + 1} of #{num}"
	puts a.user.name 
	puts a.text 
	puts "http://twitter.com/#!/#{a.user.screen_name}/status/#{a.id}" 
	if a.retweeted_status
		puts "RETWEETED"
		puts a.retweeted_status.text
	end
	if a.in_reply_to_status_id 
		puts "in reply to"
		puts get_reply_chain(a.id)
	end
	puts a.created_at
	puts "---------------------------------------------------------------"
	cmd = ask("reply, retweet, next or quit:  ", ["","r","rt","n","q"]) { |q| q.readline }
	if cmd == "q"
		new_since = a.id
		break
	elsif cmd == "n" or cmd == ""
		next
	end
}

open(cfs,'w') { |f| f.write(new_since) }
# Get your rate limit status
puts client.rate_limit_status.remaining_hits.to_s + " Twitter API request(s) remaining this hour"
