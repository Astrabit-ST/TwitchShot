module Twitch
  class InputOverlay
    Strings = {
      Input::UP => "UP",
      Input::DOWN => "DOWN",
      Input::LEFT => "LEFT",
      Input::RIGHT => "RIGHT",
      Input::RUN => "RUN",
      Input::ACTION => "ACTION",
      Input::MENU => "MENU",
      Input::ITEMS => "ITEMS",
      Input::CANCEL => "CANCEL",
      Input::DEACTIVATE => "DEACTIVATE",
      Input::L => "STATISTICS",
      Input::SETTINGS => "SETTINGS",
      Input::R => "SKIP",
      Input::PAUSE => "PAUSE",
    }

    def initialize
      @bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @bitmap.font.size = 14
      @sprite = Sprite.new
      @sprite.bitmap = @bitmap
      @sprite.z = 10000

      @inputs = []
    end

    def update
      @inputs = Input.queue[0]

      redraw
    end

    def redraw
      @bitmap.clear
      @inputs.each_with_index do |input, index|
        rect = @bitmap.text_size(Strings[input])
        @bitmap.draw_text(640 - 128, index * rect.height + 16, rect.width, rect.height, Strings[input])
      end
    end
  end
end
