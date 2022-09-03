The Twitch folder inside Scripts can be copied over into an unpacked xScripts folder, just make sure to append the files in _scripts.txt in the right order.
If you are using the RMXP script editor, please stop and use something else for your own sanity.

This is because the moment Twitch/twitch is loaded the bot starts- so be mindful of that.

If you have overloaded EdText, Graphics.update, Input.update, or print functions you should be okay. 
Otherwise, you have nothing to worry about.

An installation of concurrent-ruby, concurent-ruby-ext and concurrent-ruby-edge is provided, but if you use them make sure you are running a ruby 3.1 build of ModShot. You have been warned.

This mod also makes decent use of threads, which may, in some situations, result in random crashes if threads are used elsewhere 
in your mod. This is most likely a bug with your mod not handling thread safety properly to begin with; the extra threads from the
bot are affecting when your threads run bringing those problems to light. 
If you are crashing, please check that you are not calling graphics or input functions from threads.



The bot is fully configurable from twitch_config.json. There's some examples explaining what you need to fill out in the file.
If you need help getting an oauth key, try looking at https://twitchapps.com/tmi/

