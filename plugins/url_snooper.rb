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
require 'mechanize'

module Plugins
  class URLSnooper
    include Cinch::Plugin
    include Cinch::Helpers
    include ActionView::Helpers::DateHelper

    enable_acl(:nobody, false)

    # Default list of URL regexps to ignore.
    # DEFAULT_BLACKLIST = [/\.png$/i, /\.jpe?g$/i, /\.bmp$/i, /\.gif$/i, /\.pdf$/i].freeze

    set :help, <<-HELP
  http[s]://...
    I’ll fire a GET request at any link I encounter, parse the HTML
    meta tags, and paste the result back into the channel.
    HELP

    match %r{\b((https?:\/\/)?(([0-9a-zA-Z_!~*'().&=+$%-]+:)?[0-9a-zA-Z_!~*'().&=+$%-]+\@)?(([0-9]{1,3}\.){3}[0-9]{1,3}|([0-9a-zA-Z_!~*'()-]+\.)*([0-9a-zA-Z][0-9a-zA-Z-]{0,61})?[0-9a-zA-Z]\.[a-zA-Z]{2,6})(:[0-9]{1,4})?((\/[0-9a-zA-Z_!~*'().;?:\@&=+$,%#-]+)*\/?))}i,
          use_prefix: false,
          react_on: :channel

    def execute(msg, url)
      url = "http://#{url}" unless url=~/^https?:\/\//
      url = URI.encode(url)

      # Ignore items on blacklist
      # blacklist = DEFAULT_BLACKLIST.dup
      # blacklist.concat(config[:blacklist]) if config[:blacklist]
      # return if blacklist.any?{|entry| url =~ entry}

      # Log
      debug "URL matched: #{url}"

      # Parse URI
      p = URI(url)

      # API key lookup
      VideoInfo.provider_api_keys = { youtube: Zsec.google }

      # Parse out specific websites
      if p.host == 'youtube.com' || p.host == 'www.youtube.com' || p.host == 'youtu.be'
        match_youtube(msg, url)
      elsif p.host == 'i.imgur.com' || p.host == 'imgur.com'
        match_imgur(msg, url)
      else
        match_other(msg,url)
      end

    rescue => e
      error "#{e.class.name}: #{e.message}"
      error "[404] #{msg.user.authname} - #{url}"
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
      id = url.to_s.match(%r{(?:https?://i?\.?imgur.com/)(?:.*\/)?([A-Za-z0-9]+)(?:\.jpg|png|gif|gifv)?}i)
      return match_other(msg, url) unless id

      # Query Data
      data = JSON.parse(
          RestClient.get("https://api.imgur.com/3/image/#{id[1]}", { Authorization: "Client-ID #{Zsec.imgur.id}" })
      )
      return 'Unable to query imgur' unless defined?(data)
      i = Hashie::Mash.new(data)

      # SET Not Safe For Work
      if i.data.nsfw
        nsf = "[#{Format(:red, 'NSFW')}]"
      else
        nsf = "[#{Format(:green, 'SAFE')}]"
      end

      # Trigger reply message
      msg.reply("#{Format(:purple, 'IMGUR')} #{nsf} ∴ [#{Format(:yellow, i.data.type)}] #{i.data.width}x#{i.data.height} "\
              "∴ Views: #{ i.data.views.to_s} ∴ #{i.data.title ? i.data.title[0..100] : 'No Title'} "\
              "∴ Posted #{time_ago_in_words(Time.at(i.data.datetime))} ago")
    end

    def match_other(msg,url)
      begin
        html = Mechanize.start { |m| Nokogiri::HTML(m.get(url).content, nil, 'utf-8') }
        if node = html.at_xpath("html/head/title")
          msg.reply("‡ #{node.text.lstrip.gsub(/\r|\n|\n\r/, ' ')[0..300]}")
        end

        if node = html.at_xpath('html/head/meta[@name="description"]')
          msg.reply("» #{node[:content].lines.first(3).join.gsub(/\r|\n|\n\r/, ' ')[0..300]}")
        end

        info "[200] #{msg.user.authname} - #{url}"
      rescue => e
        error e
        error "[404] #{msg.user.authname} - #{url}"
      end
    end

  end
end


# AutoLoad
Zeta.config.plugins.plugins.push Plugins::URLSnooper

