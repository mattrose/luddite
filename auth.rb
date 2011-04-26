require 'rubygems'
require 'twitter_oauth'
require 'twitter'
require 'highline/import'
session = {}
if ARGV.length < 2
	puts "Usage: auth.rb consumer_key consumer_secret"
	exit 1
end
k = ARGV[0]
s = ARGV[1]

p k
p s
begin 
client = TwitterOAuth::Client.new(
    :consumer_key => k,
    :consumer_secret => s
  )
rescue Exception => e
	puts "Couldn't get request_token, double-check yr credentials"
	exit 1
end

p client
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

p access_token.params[:oauth_token]
p access_token.params[:oauth_token_secret]

Twitter.configure do |config|
  config.consumer_key = k
  config.consumer_secret = s
  config.oauth_token = access_token.params[:oauth_token]
  config.oauth_token_secret = access_token.params[:oauth_token_secret]
end

client = Twitter::Client.new
p client.home_timeline
