module Admin
  class BotAdmin
    include Cinch::Plugin

    set(
      plugin_name: "BotAdmin",
      help: "Bot administrator-only private commands.\nUsage: `~nick [channel]`;",
      prefix: /^~/)

    match /nick (.+)/, method: :nick
    def nick(m, nick)
      return unless get_user(m).is_admin?
      bot.nick = nick
      synchronize(:nickchange) do
        @bot.handlers.dispatch :admin, m, "My nick got changed from #{@bot.last_nick} to #{@bot.nick} by #{m.user.nick}", m.target
      end
    end

    match /mode (.+)/, method: :mode
    def mode(m, nick)
      return unless get_user(m).is_admin?
      bot.modes = m
    end

    match /eval (.+)/, method: :boteval
    def boteval(m, s)
      return unless get_user(m).is_owner?
      eval(s)
    rescue => e
      m.user.msg "eval error: %s\n- %s (%s)" % [s, e.message, e.class.name]
    end

  end
end