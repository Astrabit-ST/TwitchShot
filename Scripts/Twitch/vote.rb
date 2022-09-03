require "concurrent"

module Twitch
  class Vote
    attr_reader :total_votes, :percentage, :votes, :users, :name, :finished

    def initialize(total_votes, name, percentage = 0.3, timeout = 30)
      @total_votes = (total_votes * percentage).ceil
      @total_votes = 5 if @total_votes > 6
      @name = name
      @votes = 0
      @users = []
      @finished = false

      @timeout_task = Concurrent::ScheduledTask.new(timeout) do
        @finished = true
        @fail_callback.call
      end
      @timeout_task.execute
    end

    def add_vote(user)
      return "You already voted!" if @users.include?(user)
      @users << user
      @votes += 1

      if @votes >= @total_votes
        @timeout_task.cancel
        @success_callback.call
        @finished = true
        return "Vote succeeded!"
      end
      return "Vote cast! (#{@votes}/#{@total_votes})"
    end

    def success_callback(&block)
      @success_callback = block
    end

    def fail_callback(&block)
      @fail_callback = block
    end
  end
end
