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

    # the rotator instance
    attr_reader :rotator

    # Returns an Array of Strings specifying dirty files. These files will be
    # +rm -rf+ when the +cleanup+ task is called.
    attr_reader :dirty_files

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
      @dirty_files = []
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

      if self.respond_to?(name) && !( block_given? || options[:method] )
        # if it was already defined and we aren't trying to re-define it then
        # what we are trying to do is define it the same way it is defined now
        # only with options being sent to it. 
        metaclass.send(:alias_method, "old_#{name}".intern, name)
        #self.class.send(:alias_method, "old_#{name}".intern, name)
        #define_method("#{name.to_s}_new".intern) do
        define_method(name) do
          begin
           result =  self.send("old_#{name}", options)
          end
          result
        end
        return
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
    def via_s3;  rotator.rotate_via_s3(last_result);   end

    # By default, +:content+ can perform one of three actions
    # * +:is_file+
    # * +:is_folder+
    # + +:is_contents_of+
    # 
    # Examples:
    #   action :content, :is_file        => "/path/to/file"          # content is a single file
    #   action :content, :is_folder      => "/path/to/folder"        # content is the folder itself
    #   action :content, :is_contents_of => "/path/to/other/folder"  # files in folder/
    # 
    # +:is_file+ and +:is_folder+ are basically the same thing in that they
    # backup the whole file/folder whereas +:is_contents_of+ backs up the
    # <em>contents</em> of the given folder.
    #
    # Note that +:is_contents_of+ performs a very spcific action: 
    # * a temporary directory is created
    # * all of the files are moved (including subdirectories) into the temporary directory
    # * the archive is created from the temporary directory
    #
    # If you wish to copy the files out of the original directory instead of
    # moving them. Then you may specify the +copy+ option passing a +true+
    # value like so:
    #
    #   action :content, :is_contents_of => "/path/to/other/folder",
    #                              :copy => true
    #
    # This will copy recursively. 
    #
    # If this is not your desired behavior then you can easily write your own.
    # Also, these options only work for local files. If you are getting the
    # files from a foreign server you will have to write a custom +:content+
    # method.
    #
    def content(opts={})
      return opts[:is_file]        if opts[:is_file] 
      return opts[:is_folder]      if opts[:is_folder]
      if opts[:is_contents_of]
        orig   = opts[:is_contents_of]
        tmpdir = c[:tmp_dir] + "/tmp_" + Time.now.strftime("%Y%m%d%H%M%S") +"_#{rand}"
        new_orig = tmpdir + "/" + File.basename(orig)
        mkdir_p tmpdir
        mkdir_p new_orig
        if opts[:copy]
          cp_r orig + '/.', new_orig
        else
          mv orig + '/.', new_orig
        end
        dirty_file new_orig
        return new_orig
      end
      if opts[:is_hg_repository]
        orig = opts[:is_hg_repository]
        name = opts[:as] || File.basename(orig)
        new_orig = c[:tmp_dir] + '/' + name
        sh "hg clone #{orig} #{new_orig}"
        dirty_file new_orig
        return new_orig
      end
      raise "Unknown option in :content. Try :is_file, :is_folder " +
            ":is_contents_of or :is_hg_repository"
    end

    # Given name of a file in +string+ adds that file to @dirty_files. These
    # files will be removed when the +cleanup+ task is called.
    def dirty_file(string)
      @dirty_files << string
    end

    # +cleanup+ takes every element from @dirty_files and performs an +rm -rf+ on the value
    def cleanup(opts={})
      dirty_files.each do |f|
        rm_rf f
      end
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
