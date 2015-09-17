module Admin
  class BotAutoVoice
    include Cinch::Plugin
    include Cinch::Helpers

    enable_acl(:operator)

    set(
        plugin_name: "BotAuto",
        help:        "Listen's for automatic modes",
    )
    listen_to :channel
    match /autovoice (on|off|refresh)$/

    # Initialization
    def initialize(*args)
      super
      @channels = Zchannel.where(auto_voice: true).map(:name)
      @ignore = Zuser.where(ignore: true).map(:authname)
      @users = {}
    end

    def listen(m)
      # Autovoice Enabled?
      if @channels.member? m.channel
        # Respect the ignore list
        return if defined?(m.user.authname) && @ignore.member?(m.user.authname)

        # Ignore bot
        unless m.user.nick == bot.nick

          # Ignore users that are not identified
          if defined? m.user.authname && m.user.nick != bot.nick
            @users[m.channel] = Hash.new unless @users.has_key?(m.channel)
            @users[m.channel][m.user.authname] = Time.now

            # Make sure Bot is either Opped or Half Opped
            if m.channel.opped?(bot.nick) || m.channel.half_opped?(bot.nick)

              # Don't try to voice users that are opped half_opped or voiced already...
              unless m.channel.opped?(m.user) || m.channel.voiced?(m.user) || m.channel.half_opped?(m.user)
                m.channel.voice(m.user)
              end

              # Check for timed out, thus devoice user
              timer(m)
            end
          end
        end

      end
    end

    def execute(m, option)
      c = check_channel(m)
      if option == 'on'
        Zchannel.where(id: c.id).update(auto_voice: true)
        @channels = Zchannel.where(auto_voice: true).map(:name)
        @ignore = Zuser.where(ignore: true).map(:authname)
        m.reply 'Autovoice Enabled!'
      elsif option == 'refresh'
        @ignore = Zuser.where(ignore: true).map(:authname)
        m.reply 'Autovoice refreshed'
      else
        Zchannel.where(id: c.id).update(auto_voice: false)
        @channels = Zchannel.where(auto_voice: true).map(:name)
        @ignore = Zuser.where(ignore: true).map(:authname)
        m.reply 'Autovoice Disabled'
      end
    end


    def timer(m)
      # Do not run if there is no users in the recent list
      return unless @users.key?(m.channel)

      # Remove users from @users if their time has expired
      @users[m.channel].delete_if do |k,v|
        v <= Time.now - 3600
        end

      # Return a difference from the total voiced users and the ones that we want to remove
      chan = @users[m.channel]
      userlist = m.channel.voiced.delete_if{|u| chan.key?(u.authname)}

      # No changes to voiced users - finish
      return if userlist.count == 0

      # Count the number of users to be changed
      modes = 'v' * userlist.count

      # Mass mode change
      # TODO Limit how many users can be mass mode. irc limitation
      @bot.irc.send "MODE #{m.channel} -#{modes} #{userlist.flatten.join(' ')}"
    end

  ##
  end
##
end


# AutoLoad
Zeta.config.plugins.plugins.push Admin::BotAutoVoice