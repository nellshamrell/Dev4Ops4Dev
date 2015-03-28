#!/usr/bin/env ruby

require 'droplet_kit'
require 'optparse'
require 'byebug'

def main()
  opts = parse_command_line_opts()
  the_center_does_not_hold(opts)
end

def parse_command_line_opts()
  parsed_options = {}

  # Set defaults
  parsed_options[:environment] = 'testing'
  parsed_options[:mercy] = []
  parsed_options[:smite] = []
  parsed_options[:wait] = 1000
  parsed_options[:chance] = 10

  OptionParser.new do |cfg|
    cfg.banner = "Usage: chaos.rb [options]"

    #   prod or testing
    cfg.on("-p", "--production", "Run against production env") do |e|
      parsed_options[:environment] = 'production'
    end
    cfg.on("-t", "--testing", "Run against testing env") do |e|
      parsed_options[:environment] = 'testing'
    end

    #   group(s) to have mercy on 
    cfg.on("-mGROUP", "--mercy GROUP", "Spare GROUP from chaos") do |m|
      parsed_options[:mercy] << m
    end

    #   groups to smite
    cfg.on("-sGROUP", "--smite GROUP", "Ensure chaos hits GROUP") do |s|
      parsed_options[:smite] << s
    end

    #   sleep time
    cfg.on("-wMSEC", "--wait MSEC", "Wait MSEC milliseconds between droplets", OptionParser::DecimalInteger) do |w|
      parsed_options[:wait] = w
    end

    #   chance of chaos
    cfg.on("-cPCT", "--chance PCT", "Percent (1-100) chance of chaos.", OptionParser::DecimalInteger) do |c|
      parsed_options[:chance] = c
    end
    
  end.parse!
  return parsed_options

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
