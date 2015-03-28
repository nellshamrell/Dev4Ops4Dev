#!/usr/bin/env ruby

require 'droplet_kit'
require 'net/ssh'
require 'optparse'

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
  parsed_options[:wait] = 1
  parsed_options[:chance] = 10
  parsed_options[:service] = 'httpd'

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
    cfg.on("-wSEC", "--wait SEC", "Wait SEC seconds between droplets", OptionParser::DecimalInteger) do |w|
      parsed_options[:wait] = w
    end

    #   chance of chaos
    cfg.on("-cPCT", "--chance PCT", "Percent (1-100) chance of chaos.", OptionParser::DecimalInteger) do |c|
      parsed_options[:chance] = c
    end

    #   which service to hit
    cfg.on("-SSVC", "--service SVC", "Name of service to kill") do |s|
      parsed_options[:service] = s
    end
    
  end.parse!
  return parsed_options

end

def dropname2groupname(dname)
  # testing-vm-#{group name}.vm.io 
  return dname.split('.')[0].split('-')[-1]
end

def dropname2envname(dname)
  # testing-vm-#{group name}.vm.io 
  return dname.split('.')[0].split('-')[0]
end

def log (level, msg)
  return if level == :debug
  time = DateTime.now().strftime('%H:%M:%S')
  puts sprintf('%5s - %s - %s',level.to_s.upcase(), time, msg) 
end


def the_center_does_not_hold(opts)
  log(:info, "Connecting to DO")
  dk = DropletKit::Client.new(access_token: ENV['DIGITALOCEAN_ACCESS_TOKEN'])

  # Loop forever
  while true do
    #   Fetch a list of running droplets
    log(:info, "Fetching droplet list")
    drops = dk.droplets.all.sort { |a,b| a.name <=> b.name }

    #   Filter based on status
    inactive = drops.select { |d| d.status != 'active' }
    drops -= inactive

    #   Filter based on mercy
    pardoned = drops.select { |d| opts[:mercy].include?(dropname2groupname(d.name)) }
    drops -= pardoned

    #   Filter based on prod or testing
    nimby = drops.select { |d| opts[:environment] != dropname2envname(d.name) }
    drops -= nimby

    # TODO: report on counts   


    #   Loop over droplets
    drops.each do |drop|
      log(:info, "Examining droplet #{drop.name}")

      #     Connect via SSH
      ssh_opts = {
        auth_methods: ['publickey'], # We are relying on the proper SSH key being in the agent
        paranoid: false, # Disables strict hostkey checking
      }
      Net::SSH.start(drop.public_ip, 'root', ssh_opts) do |ssh|
        #        check for running service
        output = ssh.exec!("service #{opts[:service]} status")
        log(:debug, "Service status output:\n\t#{output}")
        #          if running
        if output =~ /running, process/ then
          #            roll dice
          snake_eyes = rand(100) < opts[:chance]
          doomed_anyway = opts[:smite].include?(dropname2groupname(drop.name))
          #            based on dice and smite
          if snake_eyes or doomed_anyway then            
            #            halt service
            log(:info, "           BURN ORDER!    ")
            output = ssh.exec!("service #{opts[:service]} stop")
            log(:info, " ~~~ sad trombone ~~~ (due to chaos)") if snake_eyes
            log(:info, " ~~~ sad trombone ~~~ (due to smite)") if doomed_anyway
            log(:debug, "Service halt output:\n\t#{output}")
          end
        else
          log(:info, "Service #{opts[:service]} missing or not running")
        end        
      end

      #     sleep
      log(:debug, "Waiting a bit")
      sleep(opts[:wait])
    end
  end
end

Signal.trap('SIGINT') do
  puts "Exiting"
  exit(0)
end

main()
