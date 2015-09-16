unless defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
  require 'mkfifo'
end

# Named pipe plugin for Cinch.
module Plugins
  class Fifo
    include Cinch::Plugin
    listen_to :connect, :method => :open_fifo
    listen_to :disconnect, :method => :close_fifo

    def open_fifo(msg)
      # Sometimes FiFo is left open on crash, remove old fifo
      if File.exists?("#{$root_path}/tmp/zeta.io")
        File.delete("#{$root_path}/tmp/zeta.io")
      end

      File.mkfifo("#{$root_path}/tmp/zeta.io" || raise(ArgumentError, "No FIFO path given!"))
      File.chmod(0660, "#{$root_path}/tmp/zeta.io")

      File.open("#{$root_path}/tmp/zeta.io", "r+") do |fifo|
        bot.info "Opened named pipe (FIFO) at #{$root_path}/tmp/zeta.io"

        fifo.each_line do |line|
          msg = line.strip
          bot.debug "Got message from the FIFO: #{msg}"
          bot.irc.send msg
        end
      end

    end

    def close_fifo(msg)
      File.delete("#{$root_path}/tmp/zeta.io")
      bot.info "Deleted named pipe #{$root_path}/tmp/bot."
    end

  end
end


# AutoLoad if Not Jruby
unless defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
  Zeta.config.plugins.plugins.push Plugins::Fifo
end
