require "open-uri"

module Twitch
  class Bot
    NO_VOTE_TEXT = "No vote in progress!"
    ALREADY_VOTE = "There is already a vote in progress!"
    RECENTLY_VOTED = "Too soon! Can start a new vote in {0} seconds"

    VOTE_TIME_INTERVAL_SECONDS = 120

    def command(user, command, reply_id = nil)
      response = if command.match(/^#{Config["prefix"]}ping/)
          "Pong!"
        elsif command.match(/^#{Config["prefix"]}uptime/)
          URI.open("https://decapi.me/twitch/uptime/#{Config["channel"]}?offline_msg=#{Config["offline_message"]}").string
        elsif command.match(/^#{Config["prefix"]}version/)
          "TwitchShot Version: #{Config::VERSION}"
        elsif command.match(/^#{Config["prefix"]}channel/)
          "The current channel is #{@channel}"
        elsif command.match(/^#{Config["prefix"]}shake/)
          shake_vote
        elsif command.match(/^#{Config["prefix"]}vote_results/)
          if @vote
            "The vote results are #{@vote.votes}/#{@vote.total_votes}}% for #{@vote.name}"
          else
            NO_VOTE_TEXT
          end
        elsif command.match(/^#{Config["prefix"]}current_vote/)
          if @vote
            "The current vote is #{@vote.name}"
          else
            NO_VOTE_TEXT
          end
        elsif command.match(/^#{Config["prefix"]}vote/)
          if @vote
            @vote.add_vote(user)
          else
            NO_VOTE_TEXT
          end
        elsif command.match(/^#{Config["prefix"]}close/)
          close_vote
        elsif match = command.match(/^#{Config["prefix"]}up ?([1-5]?)/)
          # These commands work by telling the main ractor to queue a key
          # It has to be on the main ractor, because of class variables
          send_input(Input::UP, match[1])
        elsif match = command.match(/^#{Config["prefix"]}down ?([1-5]?)/)
          send_input(Input::DOWN, match[1])
        elsif match = command.match(/^#{Config["prefix"]}left ?([1-5]?)/)
          send_input(Input::LEFT, match[1])
        elsif match = command.match(/^#{Config["prefix"]}right ?([1-5]?)/)
          send_input(Input::RIGHT, match[1])
        elsif match = command.match(/^#{Config["prefix"]}run/)
          Settings[:default_run] = !Settings[:default_run]
        elsif match = command.match(/^#{Config["prefix"]}action ?([1-5]?)/)
          send_input(Input::ACTION, match[1])
        elsif match = command.match(/^#{Config["prefix"]}menu/)
          send_input(Input::MENU, match[1])
        elsif match = command.match(/^#{Config["prefix"]}items/)
          send_input(Input::ITEMS, match[1])
        elsif match = command.match(/^#{Config["prefix"]}cancel ?([1-5]?)/)
          send_input(Input::CANCEL, match[1])
        elsif match = command.match(/^#{Config["prefix"]}deactivate ?([1-5]?)/)
          send_input(Input::DEACTIVATE, match[1])
        elsif match = command.match(/^#{Config["prefix"]}statistics/)
          send_input(Input::L, match[1])
        elsif match = command.match(/^#{Config["prefix"]}settings/)
          send_input(Input::SETTINGS, match[1])
        elsif match = command.match(/^#{Config["prefix"]}pause/)
          send_input(Input::PAUSE, match[1])
        else
          "Unknown command #{command}, #{user}."
        end

      if response.is_a?(String)
        response = "PRIVMSG ##{@channel} :#{response}"
        response = "@reply-parent-msg-id=#{reply_id} #{response}" if reply_id
        Twitch.queue(response)
        Log.log("#{user} used: #{command}, responded with: #{response}\n", Log::LogLevel::INFO)
      else
        Log.log("#{user} used: #{command}\n", Log::LogLevel::INFO)
      end
    end

    def deny_vote_message()
      @last_vote_time ||= 0
      return ALREADY_VOTE if @vote

      vote_interval = Time.now.to_i - @last_vote_time
      return RECENTLY_VOTED.gsub("{0}", (VOTE_TIME_INTERVAL_SECONDS - vote_interval).to_s) if VOTE_TIME_INTERVAL_SECONDS > vote_interval
    end

    def setup_vote(name)
      chatters_str = URI.open("http://tmi.twitch.tv/group/user/#{Config["channel"]}/chatters").string
      chatters = JSON.parse(chatters_str)

      total_chatters = chatters["chatter_count"]
      @vote = Vote.new(total_chatters, name)
    end

    def close_vote
      deny = deny_vote_message()
      return deny if deny

      setup_vote("Close the game")

      @vote.success_callback do
        Twitch.immediate("PRIVMSG ##{@channel} :*dies*")
        Input.quit = true
        @vote = nil
      end
      @vote.fail_callback do
        Twitch.queue("PRIVMSG ##{@channel} :Vote failed :(")
        @vote = nil
        @last_vote_time = 0
      end

      return "Vote started (#{@vote.total_votes} needed)! Type !vote to cast your vote in favor of closing the game."
    end

    def shake_vote
      deny = deny_vote_message()
      return deny if deny

      setup_vote("Shake the screen")

      @vote.success_callback do
        Oneshot.shake
        Twitch.queue("PRIVMSG ##{@channel} :*shakes*")
        @vote = nil
        @last_vote_time = 0
      end
      @vote.fail_callback do
        Twitch.queue("PRIVMSG ##{@channel} :Vote failed :(")
        @vote = nil
        @last_vote_time = Time.now.to_i
      end

      return "Vote started (#{@vote.total_votes} needed)! Type !vote to cast your vote in favor of shaking the game screen."
    end

    def send_input(input, amount = "")
      amount = 1 if amount.nil? || amount.empty?
      amount = amount.to_i if amount.is_a?(String)
      Input.queue_input input, amount
    end
  end
end
