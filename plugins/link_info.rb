# -*- coding: utf-8 -*-
#
# = Cinch Link Info plugin
# Inspects any links that are posted into a channel Cinch
# is currently in and prints out the value of the title
# and description meta tags, if any.
#
# == Dependencies
# * Gem: nokogiri
#
# == Configuration
# Add the following to your bot’s configure.do stanza:
#
#   config.plugins[Cinch::LinkInfo] = {
#     :blacklist => [/\.xz$/]
#   }
#
# [blacklist]
#   If a URL matches any of the regular expressions defined
#   in this array, it will not be inspected. This plugin
#   alraedy ignores URLs ending in common image file
#   extensions, so you don’t have to specify .png, .jpeg,
#   etc.
#
# == Author
# Marvin Gülker (Quintus)
#
# == Modification author
# Liothen
#
# == License
# A named-pipe plugin for Cinch.
# Copyright © 2012 Marvin Gülker
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Plugin for inspecting links pasted into channels.
require 'video_info'

module Plugins
  class LinkInfo
    include Cinch::Plugin
    include Cinch::Helpers

    enable_acl(:nobody, false)

    # Default list of URL regexps to ignore.
    DEFAULT_BLACKLIST = [/\.png$/i, /\.jpe?g$/i, /\.bmp$/i, /\.gif$/i, /\.pdf$/i].freeze

    set :help, <<-HELP
  http[s]://...
    I’ll fire a GET request at any link I encounter, parse the HTML
    meta tags, and paste the result back into the channel.
    HELP

    match %r{\b((https?:\/\/)?(([0-9a-zA-Z_!~*'().&=+$%-]+:)?[0-9a-zA-Z_!~*'().&=+$%-]+\@)?(([0-9]{1,3}\.){3}[0-9]{1,3}|([0-9a-zA-Z_!~*'()-]+\.)*([0-9a-zA-Z][0-9a-zA-Z-]{0,61})?[0-9a-zA-Z]\.[a-zA-Z]{2,6})(:[0-9]{1,4})?((\/[0-9a-zA-Z_!~*'().;?:\@&=+$,%#-]+)*\/?))}i, use_prefix: false

    def execute(msg, url)
      url = "http://#{url}" unless url=~/^https?:\/\//

      # Ignore items on blacklist
      blacklist = DEFAULT_BLACKLIST.dup
      blacklist.concat(config[:blacklist]) if config[:blacklist]
      return if blacklist.any?{|entry| url =~ entry}

      # Log
      debug "URL matched: #{url}"

      # Parse URI
      p = URI(url)

      # API key lookup
      VideoInfo.provider_api_keys = { youtube: Zsec.google }

      # Parse out specific websites
      if p.host == 'youtube.com' || p.host == 'www.youtube.com' || p.host == 'youtu.be'
        match_youtube(msg, url)
      else
        match_other(msg,url)
      end

    rescue => e
      error "#{e.class.name}: #{e.message}"
    end

    private
    def match_youtube(msg, url)
      if Zsec.google
        video = VideoInfo.new(url)
        msg.reply "#{Format(:red, 'YouTube ')}∴ #{video.title} ( #{Format(:green, Time.at(video.duration).strftime("%H:%M:%S"))} )"
      else
        match_other(msg, url)
      end

    end

    def match_github(msg, url)
      # TODO parse github url
    end

    def match_imgur(msg, url)
      # TODO parse imgur url

    end

    def match_other(msg,url)
      # Open URL
      html = Nokogiri::HTML(open(url))
      if node = html.at_xpath("html/head/title")
        msg.reply(node.text.lstrip.gsub(/\r|\n|\n\r/, ' '))
      end

      if node = html.at_xpath('html/head/meta[@name="description"]')
        msg.reply(node[:content].lines.first(3).join.gsub(/\r|\n|\n\r/, ' '))
      end
    end

  end
end


# AutoLoad
Zeta.config.plugins.plugins.push Plugins::LinkInfo

