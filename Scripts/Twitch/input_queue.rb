REPEAT_INPUT = 20

module Input
  class << self
    alias :twitch_update :update
    alias :twitch_quit :quit?

    attr_accessor :queue, :quit

    def queue_input(key, amount)
      (amount * REPEAT_INPUT).times do |i|
        @queue[i] << key unless @queue[i].include?(key)
      end
    end

    def update
      twitch_update()

      if Graphics.frame_count % REPEAT_INPUT == 0
        @queue[0].each do |key|
          Input.set_key_triggered(key)
          Input.set_key_pressed(key)
          Input.set_key_repeated(key)
        end
      end
      @queue.shift

      @queue << []
    end

    def quit?
      old_quit = @quit
      @quit = false
      old_quit || twitch_quit
    end
  end
end

Input.queue = []
(REPEAT_INPUT * 9).times do |i|
  Input.queue << []
end

Input.quit = false
