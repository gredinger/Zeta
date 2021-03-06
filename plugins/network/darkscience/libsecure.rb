require 'uri'
require 'net/http'
require 'ostruct'
require 'discourse_api'
require 'action_view'

module Plugins::DarkScience
  class Libsecure
    include Cinch::Plugin
    include Cinch::Helpers
    include ActionView::Helpers::DateHelper

    self.plugin_name = 'DarkScience #libsecure'
    self.help = '?latest'

    match 'latest', method: :fetch_latest

    def fetch_latest(m)
      return unless check_user(m)
      return unless check_channel(m)
      return unless m.channel == '#libsecure' || m.channel == '#bots'

      client = DiscourseApi::Client.new('https://libsecure.so', Zsec.libsecure, Zsec.libsecure_user )
      parser = client.latest_topics.sort_by { |hash| hash['last_posted_at'] }
      data = parser.last

      m.reply "Latest → #{data['title']} -- https://libsecure.so/t/#{data['id']}"
    end

  end
end

# AutoLoad
Zeta.config.plugins.plugins.push Plugins::DarkScience::Libsecure
