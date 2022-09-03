module Twitch
  # A class representing an overlay of messages on the screen
  MAX_COUNT = 20
  START_FALLOFF = 10
  class ChatOverlay
    attr_accessor :needs_redraw

    def initialize
      # Messages is an array of hashes in this format:
      # {
      #   user: [String] <username>,
      #   message: [String] <message>,
      #   color: [Color] <color>
      # }
      @messages = []

      # Graphics and whatnot
      @bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @bitmap.font.size = 14
      @sprite = Sprite.new
      @sprite.bitmap = @bitmap
      @sprite.z = 10000
    end

    def add_message(message)
      @messages.unshift message
      @messages.pop if @messages.length >= MAX_COUNT
      @needs_redraw = true
    end

    def update
      if @needs_redraw
        @bitmap.clear
        redraw
        @needs_redraw = false
      end
    end

    def redraw
      @messages.each_with_index do |message, index|
        message[:color].alpha = 255
        if index > START_FALLOFF
         message[:color].alpha = 255 - 255 * ((index - START_FALLOFF) / (MAX_COUNT - START_FALLOFF.to_f))
        end
        @bitmap.font.color = message[:color]
        rect = @bitmap.text_size(message[:user])
        @bitmap.draw_text(16, index * rect.height + 16, rect.width, rect.height, message[:user])

        @bitmap.font.color = Window_Base.text_color(0)
        @bitmap.draw_text(rect.width + 16, index * rect.height + 16, @bitmap.text_size(message[:message]).width, rect.height, message[:message])
      end
    end
  end
end
