require "google/apis/gmail_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"
require 'sinatra/base'
require 'mail'
#require 'net/http'

#set :port, 9292

class QsCli < Sinatra::Base
  #adjust as needed
  #OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
  #OOB_URI = "http://localhost:9292/oauth2callback"
  OOB_URI = "https://technomena.com/oauth2callback"
  APPLICATION_NAME = "Gmail API Ruby Quickstart".freeze
  CREDENTIALS_PATH = "credentials.json".freeze
  # The file token.yaml stores the user's access and refresh tokens, and is
  # created automatically when the authorization flow completes for the first
  # time.
  TOKEN_PATH = "token.yaml".freeze
  #SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_SEND

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user's default browser will be launched to approve the request.
  #
  # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  get '/sorry' do
    @say = "Sorry"
    erb :index, :layout => :layout
  end
  get '/hello' do
    @say = "Hi"
    erb :index, :layout => :layout
  end
  get '/amin/:secret' do
    if params['secret'] != ENV.fetch("APP_SECRET")
      redirect "/sorry", 303
    end
    @say = "Yes"
    erb :index, :layout => :layout
  end
  get '/mail/:secret' do
    if params['secret'] != ENV.fetch("APP_SECRET")
      redirect "/sorry", 303
    end
    # Initialize the API
    service = Google::Apis::GmailV1::GmailService.new
    service.client_options.application_name = APPLICATION_NAME
    client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
    token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
    authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
    user_id = "default"
    credentials = authorizer.get_credentials user_id
    @gresp = nil
    if credentials.nil?
      url = authorizer.get_authorization_url base_url: OOB_URI
      #puts "Open the following URL in the browser and enter the " \
      #     "resulting code after authorization:\n" + url
      #@gresp = url.to_s
      #res = Net::HTTP.get_response uri
      @gresp = url.to_s
    else
      service.authorization = credentials
      puts "have legit creds"
      # Show the user's labels
      user_id = "me"
      #@result = service.list_user_labels user_id
      message              = Mail.new
      message.date         = Time.now
      message.subject      = 'Supertram p'
      message.body         = "<p>Hey Dude, how's life?</p>"
      message.content_type = 'text/html'
      message.from         = ENV.fetch("MSG_FROM")
      message.to           = ENV.fetch("MSG_TO")
      msg = message.encoded
      message_object = Google::Apis::GmailV1::Message.new(raw:message.to_s)
      begin
        @gresp = service.send_user_message(user_id, message_object)
        puts "from legit result is: #{@gresp.to_json}"
      rescue ArgumentError => e
        puts "error:"
        puts e.message
      end
    end
    erb :googMail, :layout => :layout
  end
  #give service a place to land
  get '/oauth2callback' do
    puts 'got it'
    code = params['code']
    service = Google::Apis::GmailV1::GmailService.new
    service.client_options.application_name = APPLICATION_NAME
    client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
    token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
    authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
    user_id = "default"
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
    service.authorization = credentials
    # Show the user's labels
    user_id = "me"
    #@result = service.list_user_labels user_id
    message              = Mail.new
    message.date         = Time.now
    message.subject      = 'Supertram p'
    message.body         = "<p>Hi Nick, how's life?</p>"
    message.content_type = 'text/html'
    message.from         = ENV.fetch("MSG_FROM")
    message.to           = ENV.fetch("MSG_TO")
    msg = message.encoded
    message_object = Google::Apis::GmailV1::Message.new(raw:message.to_s)
    begin
      @gresp = service.send_user_message(user_id, message_object)
      puts "from oauth result is: #{@gresp.to_json}"
    rescue ArgumentError => e
      puts "error:"
      puts e.message
    end
    erb :googMail, :layout => :layout
  end
end
