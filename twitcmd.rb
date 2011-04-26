require "rubygems"
require "twitter"
require 'highline/import'

since_id = nil
cf = "#{ENV['HOME']}/.twitcmd"
cfs = "#{ENV['HOME']}/.twitcmd_since"
if File.exists?(cf)
	eval(open(cf).read)
end
if File.exists?(cfs)
        since_id = open(cfs).read.to_i
end

# Certain methods require authentication. To get your Twitter OAuth credentials,
# register an app at http://dev.twitter.com/apps
Twitter.configure do |config|
  config.consumer_key = YOUR_CONSUMER_KEY
  config.consumer_secret = YOUR_CONSUMER_SECRET
  config.oauth_token = YOUR_OAUTH_TOKEN
  config.oauth_token_secret = YOUR_OAUTH_TOKEN_SECRET
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


# Read the most recent status update in your home timeline
#client.home_timeline.first.methods.each { |a| puts a }
new_since = client.home_timeline.first.id
args = { :include_entities => 't' } 
args = { :include_entities => 't', :count => 200, :since_id => since_id } if since_id
puts "<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>"
client.home_timeline(args).reverse.each { |a| 
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
		break
		new_since = a.id
	elsif cmd == "n" or cmd == ""
		next
	end
}

open(cfs,'w') { |f| f.write(new_since) }
# Get your rate limit status
puts client.rate_limit_status.remaining_hits.to_s + " Twitter API request(s) remaining this hour"
