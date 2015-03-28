#!/usr/bin/env ruby

require 'droplet_kit'
require 'optparse'
require 'byebug'

def main()
  opts = parse_command_line_opts()
  the_center_does_not_hold(opts)
end

def parse_command_line_opts()
# Parse command line options 
#   prod or testing
#   groups to have mercy on 
#   groups to smite
#   sleep time
#   chance of chaos
end


def the_center_does_not_hold(opts)

  # dk = DropletKit::Client.new(access_token: ENV['DIGITALOCEAN_ACCESS_TOKEN'])

# Loop forever
#   Fetch a list of running droplets
#   Filter based on smite and mercy
#   Filter based on prod or testing
#   Loop over droplets
#     Connect via SSH
#        check for running service
#          if running
#            roll dice
#            based on dice and smite
#            halt service
#     sleep

end

main()
