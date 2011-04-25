require "rubygems"
require "twitter"

cf = "#{ENV['HOME']}/.twitcmd"

if File.exists?(cf)
	eval(open(cf).read)
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
#client.update("I just posted a status update via the Twitter Ruby Gem!")

# Read the most recent status update in your home timeline
#client.home_timeline.first.methods.each { |a| puts a }
client.home_timeline({ :include_entities => 't' }).each { |a| 
	puts a.text 
	puts a.user.name 
	puts "http://twitter.com/#!/#{a.user.screen_name}/status/#{a.id}" 
	if a.retweeted_status
		puts "RETWEETED"
		puts a.retweeted_status.text
	end
	puts "---------------------------------------------------------------"
}.reverse

p client.home_timeline.first.id
cfa = open(cf).readlines
cfa.collect { |l| if l =~ /since_id/ ; l == "since_id = #{client.home_timeline.first.id}" ; end }

puts cfa
# Get your rate limit status
puts client.rate_limit_status.remaining_hits.to_s + " Twitter API request(s) remaining this hour"
