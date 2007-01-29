# large portions borrowed from capistrano
require 'rubygems'
require 'net/ssh'

# TODO - add in a way to extend the belay script to work with this. thats a
# good idea for the belay script over all. write the kernal extensions, and the
# rake extensions. form there write an example third party extension.
module Backup
  class Command
    attr_reader   :command, :options
    attr_reader   :actor

    def initialize(server_name, command, callback, options, actor) #:nodoc:
      @command  = command.strip.gsub(/\r?\n/, "\\\n")
      @callback = callback
      @options  = options
      @actor    = actor
      @channels = open_channels
    end

    def process!
      since = Time.now
      loop do
        active = 0
        @channels.each do |ch|
          next if ch[:closed]
          active += 1
          ch.connection.process(true)
        end

        break if active == 0
        if Time.now - since >= 1
          since = Time.now
          @channels.each { |ch| ch.connection.ping! }
        end
        sleep 0.01 # a brief respite, to keep the CPU from going crazy
      end

      #logger.trace "command finished"

      if failed = @channels.detect { |ch| ch[:status] != 0 }
        raise "command #{@command.inspect} failed"
      end

      self
    end
     
    def open_channels
      channel = actor.session.open_channel do |channel|
           channel.request_pty( :want_reply => true )
           channel[:actor] = @actor

           channel.on_success do |ch|
             #logger.trace "executing command", ch[:host]
             ch.exec command
             ch.send_data options[:data] if options[:data]
           end

           channel.on_data do |ch, data|
             puts data
             @callback[ch, :out, data] if @callback
           end

           channel.on_failure do |ch|
             #logger.important "could not open channel", ch[:host]
             # puts "we got a faulure"
             ch.close
           end

           channel.on_request do |ch, request, reply, data|
             ch[:status] = data.read_long if request == "exit-status"
           end

           channel.on_close do |ch|
             ch[:closed] = true
           end
      end
      [channel]
    end
  end  # end Class Command

  class SshActor
     
    #def self.new_for_ssh(server_name)
    #  a = new(server_name)
    #end 

    attr_reader :session
    attr_reader :config
    alias_method :c, :config

    def initialize(config)
      @config = config
    end

    def connect
      c[:servers].each do |server| # todo, make this actually work
      @session = Net::SSH.start(
           server,
           :port         => c[:port],
           :username     => c[:ssh_user],
           :host_key     => "ssh-rsa",
           :keys         => [ c[:identity_key] ],
           :auth_methods => %w{ publickey } )
      end
    end

    def run(cmd, options={}, &block)
      #logger.debug "executing #{cmd.strip.inspect}"
      puts "executing #{cmd.strip.inspect}"
      command = Command.new(@server_name, cmd, block, options, self)
      command.process! # raises an exception if command fails on any server
    end

    def on_remote(&block)
      connect
      self.instance_eval(&block)
      close
    end

    def close
      @session.close
    end

    def verify_directory_exists(dir)
      run "if [ -d '#{dir}' ]; then true; else mkdir -p '#{dir}'; fi"
    end

    def cleanup_directory(dir, keep)
      puts "Cleaning up" 
      cleanup = <<-END
      LOOK_IN="#{dir}"; COUNT=`ls -1 $LOOK_IN | wc -l`; MAX=#{keep}; if (( $COUNT > $MAX )); then let "OFFSET=$COUNT-$MAX"; i=1; for f in `ls -1 $LOOK_IN | sort`; do if (( $i <= $OFFSET )); then CMD="rm $LOOK_IN/$f"; echo $CMD; $CMD; fi; let "i=$i + 1"; done; else true; fi
      END
      run cleanup # todo make it so that even this can be overridden
    end

   end # end class SshActor

end # end Module Backup
