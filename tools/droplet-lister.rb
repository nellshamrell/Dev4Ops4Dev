#!/usr/bin/env ruby

require 'droplet_kit'
#require 'byebug'

dk = DropletKit::Client.new(access_token: ENV['DIGITALOCEAN_ACCESS_TOKEN'])

drops = dk.droplets.all.sort { |a,b| a.name <=> b.name }

drops.each do |drop|
  line = ""
  line += drop.name
  line += "\t" + drop.public_ip
  line += "\t" + drop.status
  puts line
end

