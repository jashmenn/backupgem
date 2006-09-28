require 'rake'

module Backup
  include FileUtils
  # An Actor is the entity that actually does the work of determining which
  # servers should be the target of a particular task, and of executing the
  # task on each of them in parallel. An Actor is never instantiated
  # directly--rather, you create a new Configuration instance, and access the
  # new actor via Configuration#actor.
  class Actor
    # The configuration instance associated with this actor.
    attr_reader :configuration

    # Alias for #configuration
    alias_method :c, :configuration

    # A hash of the tasks known to this actor, keyed by name. The values are
    # instances of Actor::Action.
    attr_reader :action

    # A stack of the results of the actions called
    attr_reader :result_history

    attr_reader :rotator

    class Action #:nodoc:
      attr_reader :name, :actor, :options

      def initialize(name, actor, options)
        @name, @actor, @options = name, actor, options
      end
    end

    def initialize(config) #:nodoc:
      @configuration = config
      @action = {}
      @result_history = []
      @rotator = Backup::Rotator.new(self)
    end

    # each action in the action_order is part of the chain. so you start by
    # setting the output as 'nil' then you try to call before_ action, then
    # store the output, then cal action with the args if action takes the args
    # you are sending. if it doesnt give an intelligent error message. do this
    # for all actions. then call after_action with the output if it exists.
    # each time out are calilng the method with the arguemtns f the method
    # exists and the method takes the arguments.     
    def start_process!
      configuration[:action_order].each do |a|
        self.send_and_store("before_" + a)
        self.send_and_store(a)
        self.send_and_store("after_"  + a)
      end
      last_result
    end

    def send_and_store(name) 
        store_result self.send(name) if self.respond_to? name 
    end

    # Define a new task for this actor. The block will be invoked when this
    # task is called.
    # todo, this might be more complex if the before and after tasks are going
    # to be part of the input and output chain
    def define_action(name, options={}, &block)
      @action[name] = (options[:action_class] || Action).new(name, self, options)

      if self.respond_to?(name) && !block_given? 
        puts "i respond to and no block was given"
        # if it was already defined and we aren't trying to re-define it then
        # what we are trying to do is define it the same way it is defined now
        # only with options being sent to it. 
        #metaclass.send(:alias_method, "old_#{name}".intern, name)
        self.class.send(:alias_method, "old_#{name}".intern, name)
        define_method("#{name.to_s}_new".intern) do
          puts "im in the content_new"
          begin
            self.send("old_#{name}", options)
          end
        end
      end

      define_method(name) do
        #logger.debug "executing task #{name}"
        begin
          if block_given?
            result = instance_eval( &block )
          elsif options[:method]
            #result = self.send(options[:method], options[:args])
            result = self.send(options[:method])
            # here we need to have a thing where we can send the arguments
            # define the method 'content' so that would take the other options
            # if there are options (any hash) just send along that hash. this needs more work
          end
        end
        result
      end

    end

    def metaclass
      class << self; self; end
    end

    # rotate Actions
    def via_mv;  rotator.rotate_via_mv(last_result);   end
    def via_ssh; rotator.rotate_via_ssh(last_result);  end
    def via_ftp; rotator.rotate_via_ftp(last_result);  end

    # By default, +:content+ can perform one of three actions
    # * +:is_file+
    # * +:is_folder+
    # + +:is_contents_of+
    # 
    # +:is_file+ and +:is_folder+ are basically the same thing in that they
    # backup the whole file/folder whereas +:is_contents_of+ backs up the
    # <em>contents</em> of the given folder.
    # 
    # These options only work for local files. If you are getting the files
    # from a foreign server you will have to write a custom +:content+ method.
    #
    #   action :content, :is_file        => "/path/to/file"          # content is a single file
    #   action :content, :is_folder      => "/path/to/folder"        # content is the folder itself
    #   action :content, :is_contents_of => "/path/to/other/folder"  # files in folder/
    def content(opts={})
      # TODO, where we're at. we are trying to get this to be redefined and to
      # have ioptions sent to us by aliasing th emethod and having the new
      # mthod clal us with options. seems easy enough. somehow this isnt
      # getting called as seen by the test and the fact that tar_bz2 is
      # complaining of no input. your mission, should you choose to accept it,
      # is to track down where this system is breaking down.  
      puts "Im in :old_content"
      return opts[:is_file]        if opts[:is_file] 
      return opts[:is_folder]      if opts[:is_folder]
      if opts[:is_contents_of]
        # make a tmpdir
        # mv the files form 
      end
      raise "Unknown option in :content. Try :is_file, :is_folder " +
            "or :is_contents_of"
    end

    private
      def define_method(name, &block)
        metaclass.send(:define_method, name, &block)
      end

      def store_result(result)
        @result_history.push result 
      end

      def last_result
        @result_history.last
      end

  end

end
