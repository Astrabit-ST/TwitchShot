require "socket"
require "concurrent"
require "concurrent-edge"

module Twitch
  # A class representing a message queue
  # Used to interface messages with the twitch irc server
  class MessageQueue < Concurrent::Actor::Context
    # Set up the message queue
    def initialize
      # Open socket
      @socket = TCPSocket.new("irc.chat.twitch.tv", 6667)

      @immediate_queue = []
      @queue = []

      run
    end

    # Spins up the 3 threads
    #   - The immediate thread sends messages to the server immediately
    #   - The queue thread sends messages to the server after a delay (2 seconds roughly)
    #   - The message thread handles incoming ractor messages
    #
    # Blocks until the bot is stopped
    def run
      # Spin up threads
      @queue_task = Concurrent::TimerTask.new(execution_interval: 2) do
        unless @queue.empty?
          message = @queue.shift
          send_data(message)
        end
      end
      @queue_task.execute

      @immediate_task = Concurrent::TimerTask.new(execution_interval: 0.1) do
        until @immediate_queue.empty?
          message = @immediate_queue.shift
          send_data(message) unless message.nil?
        end
      end
      @immediate_task.execute
    end

    def on_message(message)
      case message[0]
      when :queue
        Log.log("Queueing message: #{message[1]}", Log::LogLevel::DEBUG)
        @queue << message[1]
      when :immediate
        Log.log("Sending immediate message: #{message[1]}", Log::LogLevel::DEBUG)
        @immediate_queue << message[1]
      when :get
        Log.log("Attempting to get message\n", Log::LogLevel::DEBUG)
        ready = IO.select([@socket], nil, nil, 0.5) # Wait 0.5 seconds for a message
        message = if ready
            @socket.gets
          else
            nil
          end
        Log.log("Received message: #{message}\n", Log::LogLevel::DEBUG)
        return message
      else
        pass
      end
    end

    # Send a message to the server
    #
    # @param message [String] The message to send to the server
    def send_data(data)
      Log.log("Sending message: #{data}\n", Log::LogLevel::DEBUG)
      @socket.puts "#{data}\r\n"
    end

    def default_executor
      Concurrent.global_io_executor
    end
  end
end
