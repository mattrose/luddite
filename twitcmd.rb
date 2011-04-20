require "rubygems"
require "twitter"

# Get a user's location
puts Twitter.user("sferik").location

# Get a user's most recent status update
puts Twitter.user_timeline("sferik").first.text

# Get a status update by id
puts Twitter.status(27558893223).text

# Initialize a Twitter search
search = Twitter::Search.new

# Find the 3 most recent marriage proposals to @justinbieber
search.containing("marry me").to("justinbieber").result_type("recent").per_page(3).each do |r|
  puts "#{r.from_user}: #{r.text}"
end

# Enough about Justin Bieber
search.clear

# Let's find a Japanese-language status update tagged #ruby
puts search.hashtag("ruby").language("ja").no_retweets.per_page(1).fetch.first.text

# And another
puts search.fetch_next_page.first.text

exit

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
client.update("I just posted a status update via the Twitter Ruby Gem!")

# Read the most recent status update in your home timeline
puts client.home_timeline.first.text

# Who's your most popular friend?
puts client.friends.sort{|a, b| a.followers_count <=> b.followers_count}.reverse.first.name

# Who's your most popular follower?
puts client.followers.sort{|a, b| a.followers_count <=> b.followers_count}.reverse.first.name

# Get your rate limit status
puts client.rate_limit_status.remaining_hits.to_s + " Twitter API request(s) remaining this hour"
