require "concurrent"

module Twitch
  # This method starts the bot by spinning up various actors
  #
  # The bot actor runs the bot loop and handles incoming messages (like commands, ping, etc)
  # It gets messages from the message queue via the Twitch.get_message method, which requests
  # a message from the message queue actor.
  #
  # The message queue actor runs the message queue loop and handles sending messages to the server
  # It runs 3 threads:
  #   - The immediate thread sends messages to the server immediately
  #   - The queue thread sends messages to the server after a delay (2 seconds roughly)
  #   - The message thread handles incoming actor messages
  def self.start
    $disable_keyboard_mode = true

    Config.load_config
    Log.log("Starting bot\n", Log::LogLevel::INFO)

    # Spin up actors
    make_message_queue_actor
    make_bot_actor

    Thread.abort_on_exception = true

    @chat_overlay = ChatOverlay.new if Config["user_overlay"]
    @input_overlay = InputOverlay.new if Config["input_overlay"]
  end

  # Method to make the bot actor
  def self.make_bot_actor
    @bot = Bot.spawn(name: "bot")
    # @bot.tell([:run])
  end

  # Method to make the message queue actor
  def self.make_message_queue_actor
    @message_queue = MessageQueue.spawn(name: "Message Queue")
  end

  # This method tells the message actor to add a message to the queue
  # The message actor will send the message to the server after a delay
  #
  # @param message [String] The message to send to the server
  def self.queue(message)
    @message_queue.tell([:queue, message])
  end

  # This method tells the message actor to add a message to the immediate queue
  # The message actor will send the message to the server immediately
  #
  # @param message [String] The message to send to the server
  def self.immediate(message)
    @message_queue.tell([:immediate, message])
  end

  # This method requests a message from the message queue actor
  # It'll block until a message is available, then return it
  #
  # @return [String] The message received from the server
  def self.get_message
    @message_queue.ask!([:get])
  end

  # This method adds a message to the chat overlay
  #
  # @param message [String] The message to add to the chat overlay
  def self.overlay_add_message(message)
    @chat_overlay.add_message(message)
  end

  # This method requests the bot to send an edtext message to chat
  # All this is in place to avoid manual intervention with popups
  def self.show_edtext(message)
    @bot.tell([:edtext, message])
  end

  # This method requests the bot to start a vote and return a future
  # The future will be resolved when the vote is complete
  def self.vote_yesno(text)
    @bot.ask([:vote_yesno, text])
  end

  # This method updates the overlay
  #
  # THIS MUST BE RUN FROM THE MAIN THREAD.
  def self.update_overlay
    raise "This method MUST be run from the main thread." unless Thread.current == Thread.main

    @chat_overlay&.update
    @input_overlay&.update
  end
end

module Graphics
  class << self
    alias :twitch_update :update

    def update
      Twitch.update_overlay if Twitch::Config["user_overlay"] || Twitch::Config["input_overlay"]
      twitch_update
    end
  end
end

# Automatically start the bot when the script is loaded
Twitch.start
