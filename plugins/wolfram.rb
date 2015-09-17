require 'crack'

module Plugins
  class Wolfram
    include Cinch::Plugin
    include Cinch::Helpers
    include ActionView::Helpers::DateHelper
    enable_acl


    self.plugin_name = 'Wolfram Alpha plugin'
    self.help = 'WIP'

    match /wolfram (.+)/, method: :calculate
    match /wolframalpha (.+)/, method: :calculate
    match /calc (.+)/, method: :calculate

    def calculate(m, query)
      debug 'Query: ' + query
      url = URI.encode "http://api.wolframalpha.com/v2/query?input=#{query}&appid=#{Zsec.wolfram}&primary=true&format=plaintext"
      request = open(url).read
      data = Crack::XML.parse(request)
      pod0 = data['queryresult']['pod'][0]['subpod']['plaintext'].strip
      pod1 = data['queryresult']['pod'][1]['subpod']['plaintext'].strip
      if pod1.lines.count > 2
        m.user.send "# Wolfram Results #\n #{pod0}\n #{pod1}", true
      else
        m.reply "#{pod0} #{pod1}"
      end
    end

  end
end

# AutoLoad
Zeta.config.plugins.plugins.push Plugins::Wolfram