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

      define_method(name) do
        #logger.debug "executing task #{name}"
        begin
          if block_given?
            result = instance_eval( &block )
          elsif options[:method]
            result = self.send(options[:method])
          end
        end
        result
      end

    end

    def metaclass
      class << self; self; end
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
