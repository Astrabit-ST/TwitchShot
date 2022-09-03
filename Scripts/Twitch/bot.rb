require "concurrent"
require "concurrent-edge"

module Twitch
  # A class representing the twitch bot
  class Bot < Concurrent::Actor::Context
    def initialize
      run
    end

    # Runs the bot loop
    #
    # Blocks until the bot is stopped
    def run
      # Get the login details from the config
      @oauth, @botname, @channel = Config["oauth"], Config["botname"], Config["channel"]

      Log.log("Requesting additonal capabilities\n", Log::LogLevel::INFO)
      Twitch.immediate("CAP REQ :twitch.tv/commands")
      Twitch.immediate("CAP REQ :twitch.tv/tags")

      # Connect to the server
      Log.log("Logging in as #{@botname}\n", Log::LogLevel::INFO)
      # Send the oauth token
      Twitch.immediate("PASS #{@oauth}")
      # Send the name
      Twitch.immediate("NICK #{@botname}")
      # Send the channel we want to join
      Twitch.immediate("JOIN ##{@channel}")
      Log.log("Logged in as #{@botname}\n", Log::LogLevel::INFO)

      sleep(0.1) # Wait for the messages to go through

      # Run the bot loop
      @update_loop = Thread.new do
        loop do
          # Get the message from the server
          message = Twitch.get_message
          # Check if the message is nil
          next unless message
          begin
            update message
          rescue Exception => e
            # If there's an error, log it, and send *gurgles* to chat
            process_error e
            Twitch.immediate("PRIVMSG ##{@channel} :*gurgles*")
          end
        end
      end
    end

    # Main update method
    # This method is called every time a message is received from the server
    #
    # @param message [String] The message received from the server
    def update(message)
      # Is the message a ping?
      if message.start_with?("PING")
        Log.log("Ping!\n", Log::LogLevel::INFO)
        # If so, pong!
        Log.log("Pong!\n", Log::LogLevel::INFO)
        Twitch.immediate("PONG #{message.split[1]}")
      end

      # Extract message data
      # This is an incredibly long regex, but it works
      message_data = message.match(
        /@badge-info=(.*);badges=(.*);client-nonce=(.*);color=(.*);display-name=(.*);emotes=(.*);first-msg=(.*);flags=(.*);id=(.*);mod=(.*);returning-chatter=(.*);room-id=(.*);subscriber=(.*);tmi-sent-ts=(.*);turbo=(.*);user-id=(.*);user-type=(.*) :(.+)!(.+)PRIVMSG ##{@channel} :(.+)$/
      )
      # Each part of the data matches a specific tag in the message

      # Is the message valid?
      return unless message_data

      # Get the user, color, message_id, and message
      # Chomp each string
      color = message_data[4].chomp
      display_name = message_data[5].chomp
      message_id = message_data[9].chomp
      user = message_data[18].chomp
      message = message_data[20].chomp

      display_message(display_name, message, color) if Config["user_overlay"]

      # Is the message a command?
      if message[0] == Config["prefix"]
        # If so, process it
        command(user, message, message_id)
      else
        # If not, just log it
        Log.log("#{user} said: #{message}\n", Log::LogLevel::INFO)
      end
    end

    # Display a message on the overlay
    #
    # @param user [String] The user who sent the message
    # @param message [String] The message sent by the user
    # @param color [String] The color of the user's name
    def display_message(username, message, color)
      # Prepare message for overlay
      overlay_message = {
        user: username,
        message: " : " + message,
      }
      # If the user has a color, use it
      # Else, use the default color (White)
      # Twitch (for some reason) only sends the color of the user if its set, so we *have* to check for it
      overlay_message[:color] = unless color.nil? || color&.empty?
          # This oneliner is a doozy, let's break it down
          # Color.new(*color.chars.each_slice(2).map { |s| s.join.to_i(16) })
          #
          # Color.new means we are creating a new Color, and passing in the color data
          #
          # The * before the color data splats an array (which the rest of the oneliner evaulates to)
          # that turns it into arguments to be passed to the Color initializer
          #
          # The .delete_prefix('#').chars.each_slice(2) portion disposes of the prefix '#' and splits the color data into two-character chunks
          #
          # The .map { |s| s.join.to_i(16) } portion then joins together the two-character chunks and converts them to integers using base 16
          begin
            Color.new(*color.delete_prefix("#").chars.each_slice(2).map { |s| s.join.to_i(16) })
          rescue Exception => e
            process_error e
            Color.new(255, 255, 255)
          end
        else
          Color.new(255, 255, 255)
        end
      # Send message to overlay
      Twitch.overlay_add_message(overlay_message)
    end

    def process_error(e)
      Log.log("Error: #{e}\n", Log::LogLevel::ERROR)
      e.backtrace.each { |line| Log.log(line + "\n", Log::LogLevel::ERROR) }
    end

    def on_message(message)
      case message[0]
      when :edtext
        Twitch.queue("PRIVMSG ##{@channel} :POPUP: #{message[1]}")
      when :vote_yesno
        Log.log("Yes/No poll requested: #{message[1]}", Log::LogLevel::INFO)
        Twitch.queue("PRIVMSG ##{@channel} :POPUP: #{message[1]} (Vote for yes, say nothing for no)")
        setup_vote("Yes or No")
        result = nil
        @vote.success_callback do
          Twitch.queue("PRIVMSG ##{@channel} :POPUP RESULT: Yes")
          result = true
        end
        @vote.fail_callback do
          Twitch.queue("PRIVMSG ##{@channel} :POPUP RESULT: No")
          result = false
        end
        until @vote.finished
          sleep 0.1
        end
        @vote = nil
        return result
      when :run
        run
      else
        pass
      end
    end
  end
end
