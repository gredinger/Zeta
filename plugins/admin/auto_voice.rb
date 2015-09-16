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
    match /autovoice (on|off)$/

    # Initialization
    def initialize(*args)
      super
      @channels = Zchannel.where(auto_voice: true).map(:name)
      @users = {}
    end

    def listen(m)
      if @channels.member? m.channel
        unless m.user.nick == bot.nick
          # m.channel.voice(m.user) if m.channel.opped? bot.nick
          if defined? m.user.authname && m.user.nick != bot.nick

            @users[m.channel] = Hash.new unless @users.has_key?(m.channel)
            @users[m.channel][m.user.authname] = Time.now

            if m.channel.opped?(bot.nick) || m.channel.half_opped?(bot.nick)
              unless m.channel.opped?(m.user) || m.channel.voiced?(m.user) || m.channel.half_opped?(m.user)
                m.channel.voice(m.user)
              end
            end
          end
        end
        # Check for timed out, thus devoice user
        timer(m)
      end
    end

    def execute(m, option)
      c = check_channel(m)
      if option == 'on'
        Zchannel.where(id: c.id).update(auto_voice: true)
        @channels = Zchannel.where(auto_voice: true).map(:name)
        m.reply 'Autovoice Enabled!'
      else
        Zchannel.where(id: c.id).update(auto_voice: false)
        @channels = Zchannel.where(auto_voice: true).map(:name)
        m.reply 'Autovoice Disabled'
      end
    end


    def timer(m)
      return unless @users.key?(m.channel)
      chan = @users[m.channel]
      @users[m.channel].delete_if do |k,v|
        v <= Time.now - 3600
      end
      m.channel.voiced.each do |v|
        m.channel.devoice(v) unless chan.key?(v.authname)
      end
    end
  end

end


# AutoLoad
Zeta.config.plugins.plugins.push Admin::BotAutoVoice