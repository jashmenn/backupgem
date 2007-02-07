require 'yaml'

module Backup
  class S3Actor
    include AWS::S3
    
    attr_accessor :rotation
    
    attr_reader :config
    alias_method :c, :config

    def initialize(config)
      @config       = config
      @rotation_key = c[:rotation_object_key] ||= 'backup_rotation_index.yml'
      @access_key   = c[:aws_access] ||= ENV['AMAZON_ACCESS_KEY_ID']
      @secret_key   = c[:aws_secret] ||= ENV['AMAZON_SECRET_ACCESS_KEY']
      @bucket_key   = "#{@access_key}.#{c[:backup_path]}"
      Base.establish_connection!(
        :access_key_id     => @access_key,
        :secret_access_key => @secret_key
      )
      begin
        # Look for our bucket, if it's not there, try to create it.
        @bucket = Bucket.find @bucket_key
      rescue NoSuchBucket
        @bucket = Bucket.create @bucket_key
        @bucket = Bucket.find @bucket_key
      end   
    end

    def rotation
      object = S3Object.find(@rotation_key, @bucket.name)
      index  = YAML::load(object.value)
    end

    def rotation=(index)
      object = S3Object.store(@rotation_key, index.to_yaml, @bucket.name)
      index
    end

    # Send a file to s3
    def put(last_result)
      puts last_result
      object_key = Rotator.timestamped_prefix(last_result)
      S3Object.store object_key,
                     open(last_result),
                     @bucket.name
      object_key
    end

    # Remove a file from s3
    def delete(object_key)
      S3Object.delete object_key, @bucket.name
    end

    # Make sure our rotation index exists and contains the hierarchy we're using.
    # Create it if it does not exist
    def verify_rotation_hierarchy_exists(hierarchy)
      begin
        index = rotation
        verified_index = index.merge(init_rotation_index(hierarchy)) { |m,x,y| x ||= y }
        unless (verified_index == index)
          self.rotation = verified_index
        end
      rescue NoSuchKey
        self.rotation = init_rotation_index(hierarchy)
      end
    end

    # Expire old objects
    def cleanup(generation, keep)
      puts "Cleaning up"
      
      keys = self.rotation[generation]
      diff = keys.size - keep
      
      1.upto( diff ) do
        extra_key = keys.shift
        delete extra_key
      end
    end

    private
    
      # Create a new index representing our backup hierarchy
      def init_rotation_index(hierarchy)
        hash = {}
        hierarchy.each do |m|
          hash[m] = Array.new
        end
        hash
      end
    
  end
end
