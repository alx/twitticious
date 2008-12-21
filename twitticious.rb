# myapp.rb
require 'rubygems'
require 'sinatra'
require 'rdelicious'

get '/' do
  erb :index
end

post '/' do
  process_request
  erb :index
end

helpers do

  def process_request
  
    # Verify twitter id is correct
    if is_twitter_id?(params[:twitter_id]) or params[:twitter_public] == "yes"
      @delicious = Rdelicious.new(params[:delicious_id], params[:delicious_password])

      # Verify we can access delicious account
      if @delicious.is_connected?

        # Travelling around twitter timeline
        if params[:twitter_public] == "yes"
          # Read public timeline
          twitter = read_public_twitter()
        else
          # Read user timeline
          if params[:twitter_friends] == "include"
            # Include friends
            twitter = read_twitter(params[:twitter_id], true)
          else
            # Without friend network
            twitter = read_twitter(params[:twitter_id])
          end
        end

        twitter.each_element('//text') do |element|
          description = element.text
          # Scan for url in twitter status item
          url = description.scan(/(http:\/\/.[^<\s$]*)/)[0].to_s
          tags = description.scan(/\+.[^\s]*/).join(" ").delete('+')
          # Verify url is not null and doesnt exists in delicious account
          if !url.nil? and !url.empty? and !@delicious.url_exists?(url)
            description.slice!(url)         # Remove url from description
            description.slice!(/\+.[^\s]*/) # Remove tags
            description.slice!(/:\s*$/)     # Remove trailing ":" used to send url in twitter
            @delicious.add(url, description, tags)
          end
        end
      else
        error = "Please verify your Delicious information"
      end
    else
      error = "Please verify your Twitter information"
    end
  
    return [@delicious, error]
  end

  ###
  # Twitter methods
  ###

  # Return true if twitter_id exists
  def is_twitter_id?(twitter_id)
    resp = twitter_request(twitter_id)
    # Response is not empty and doesn't contain 404 or "not found"
    return (!resp.empty? and ((resp =~ /404/).nil? or (resp =~ /not found/).nil?))
  end

  # Return an array of last element of twitter_id timeline
  def read_twitter(twitter_id, include_friends = false)
    resp = twitter_request(twitter_id, include_friends)
    begin
      #  XML Document
      return REXML::Document.new(resp)
    rescue REXML::ParseException => e
      return false
    end
  end

  # Return an array of last element of twitter public timeline
  def read_public_twitter()
    return read_twitter("public_timeline")
  end

  def twitter_request(twitter_id, include_friends = false)
    if include_friends
      request = "/statuses/friends_timeline/#{twitter_id}.xml"
    else
      request = "/statuses/user_timeline/#{twitter_id}.xml"
    end
    response = ""
    begin      
      http = Net::HTTP.new("twitter.com")
      http.start do |http|
        req = Net::HTTP::Get.new(request, {"User-Agent" => "Twitticious"})
        response = http.request(req).body
      end
    rescue SocketError
      return false
    end
    return response
  end
  
end