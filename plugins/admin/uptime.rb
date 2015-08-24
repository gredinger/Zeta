require 'sys/proctable'
require 'action_view'

module Admin
  class BotUptime
    include Cinch::Plugin
    include Cinch::Helpers
    include ActionView::Helpers::DateHelper
    include Sys

    enable_acl(:operator)

    # Regex
    match 'uptime', method: :get_uptime
    match 'sysuptime', method: :get_sysuptime
    match 'users', method: :get_users

    def get_uptime(m)
      p = ProcTable.ps($$)
      if p.starttime.class == Time
        diff = Time.now - Time.at(p.starttime)
        uptime = Time.now - diff
      elsif p.starttime.class == Fixnum
        diff = Time.now - Time.at(p.starttime / 100)
        uptime = Time.now - diff
      else
        m.reply('Was i ever really started?')
      end

      m.reply("I have been up for #{time_ago_in_words(uptime)}.")
    end

    def get_sysuptime(m)
      m.reply(`uptime`)
    end

    def get_users(m)
      m.reply("Shell Users: #{`users`}")
    end

  end
end


# AutoLoad
Zeta.config.plugins.plugins.push Admin::BotUptime