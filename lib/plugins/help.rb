module Plugins
  class BotHelp
    include Cinch::Plugin

    set(
        plugin_name: "BotHelp",
        help: "Need help?.\nUsage: `!help`\nUsage: `!help plugin`",
    )
    match /^help (.+)$/i, method: :execute_help

    def execute_help(m, name)

      list = {}
      @bot.plugins.each { |p| list[p.class.plugin_name.downcase] = {name: p.class.plugin_name, help: p.class.help} };
      return m.user.notice("Help for \"#{name}\" could not be found.") if !list.has_key?(name.downcase)
      m.user.notice("Help for #{Format(:bold, list[name.downcase][:name])}:\n#{list[name.downcase][:help]}")
    end

    match 'list plugins', method: :execute_list
    def execute_list(m)

      list = []
      @bot.plugins.each {|p| list << p.class.plugin_name };
      m.user.notice("All #{list.size} currently loaded plugins for #{@bot.nick}:\n#{list.to_sentence}.\nTo view help for a plugin, use `!help <plugin name>`.")
    end
  end
end