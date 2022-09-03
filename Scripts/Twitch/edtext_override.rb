module EdText
  def self.msgbox(type, text)
    text = text.to_s.gsub(/\n|\\n/, " ")

    unless type == Oneshot::Msg::YESNO
      Twitch::Log.log("EdText { #{type}: #{text} } requested", Twitch::Log::LogLevel::INFO)
      Twitch.show_edtext(text)
    else
      Twitch::Log.log("YesNo { #{type}: #{text} } requested", Twitch::Log::LogLevel::INFO)
      future = Twitch.vote_yesno(text)
      until future.fulfilled?
        Graphics.update
      end
      return future.value
    end
  end
end

module Oneshot
   def self.msgbox(*args)
      Twitch::Log.log("Oneshot.msgbox used instead of EdText. Forwarding it to EdText...", Twitch::Log::LogLevel::WARN)
      EdText.msgbox(*args)
   end
end

module Kernel
  def print(*args)
    str = args.join(" ")
	 str.gsub!(/\n|\\n/, " ")
    Twitch.show_edtext(str)
  end
end
