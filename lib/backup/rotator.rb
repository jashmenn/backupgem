require "rake"

module Backup
  class Rotator
    include FileUtils

    attr_reader :actor
    attr_reader :configuration
    alias_method :c, :configuration

    def initialize(actor)
      @actor = actor
      @configuration = actor.configuration
    end

    # Take the last result and rotate it via mv on the local machine
    def rotate_via_mv(last_result)
      # verify that each of the directories exist, grandfathers, fathers, sons
      hierarchy.each { |m| verify_local_backup_directory_exists(m) }

      # place todays backup into the specified directory with a timestamp. 
      newname = timestamped_prefix(last_result)
      sh "mv #{last_result} #{place_in}/#{newname}"

      cleanup_via_mv(place_in, how_many_to_keep_today)
    end
    
    def rotate_via_ssh(last_result)
      ssh = Backup::SshActor.new(c) 
      ssh.connect 
      ssh.run "echo \"#{last_result}\""

      hierarchy.each do |m| 
        dir = c[:backup_path] + "/" + m
        ssh.verify_directory_exists(dir) 
      end  

      newname = timestamped_prefix(last_result)
      ssh.run "mv #{last_result} #{place_in}/#{newname}"

      ssh.cleanup_directory(place_in, how_many_to_keep_today)
      ssh.close
    end

    # TODO
    def rotate_via_ftp(last_result)
#      ftp = Backup::FtpActor.new(c) 
#      ftp.connect 
#
#      hierarchy.each do |m| 
#        dir = c[:backup_path] + "/" + m
#        ftp.verify_directory_exists(dir) 
#      end  
#
#      newname = timestamped_prefix(last_result)
#      ftp.run "mv #{last_result} #{place_in}/#{newname}"
#
#      ftp.cleanup_directory(place_in, how_many_to_keep_today)
#      ftp.close
    end

    def rotate_via_s3(last_result)
      s3 = Backup::S3Actor.new(c)
      s3.verify_rotation_hierarchy_exists(hierarchy)
      index = s3.rotation
      index[todays_generation] << last_result
      s3.rotation = index
      s3.cleanup(todays_generation, how_many_to_keep_today)
    end

    def create_sons_today?;     is_today_a? :son_created_on;     end
    def promote_sons_today?;    is_today_a? :son_promoted_on;    end
    def promote_fathers_today?; is_today_a? :father_promoted_on; end

    # old ( offset_days % c[:son_promoted_on] ) == 0 ? true : false
    # old ( offset_days % (c[:son_promoted_on] * c[:father_promoted_on]) ) == 0 ? true : false

    private
      def is_today_a?(symbol)
        t = $test_time || Date.today
        day = DateParser.date_from( c[symbol] )
        day.include?( t )
      end

      def verify_local_backup_directory_exists(dir)
        path = c[:backup_path]
        full = path + "/" + dir
        unless File.exists?(full) 
          sh "mkdir -p #{full}"  
        end
      end

      #def offset_days
      #  t = $test_time || Time.now # todo, write a test to use this
      #  num_from_day = Time.num_from_day( c[:promote_on] )
      #  offset = ( t.days_since_epoch + num_from_day + 0)
      #  offset
      #end

      def cleanup_via_mv(where, num_keep)

        files = Dir[where + "/*"].sort
        diff  = files.size - num_keep

        1.upto( diff ) do 
          extra = files.shift
          sh "rm #{extra}"
        end
      end

      def hierarchy 
        %w{grandfathers fathers sons}
      end

      # figure out which generation today's backup is
      public
      def todays_generation
        goes_in = promote_fathers_today? ? "grandfathers" :         \
                  promote_sons_today?    ? "fathers"      : "sons"
      end

      def self.timestamped_prefix(name)
        newname = Time.now.strftime("%Y-%m-%d-%H-%M-%S_") + File.basename(name)
      end
      
      # Given +name+ returns a timestamped version of name. 
      def timestamped_prefix(name)
        Backup::Rotator.timestamped_prefix(name)
      end

      private
      def place_in
        goes_in = todays_generation
        place_in = c[:backup_path] + "/" + goes_in
      end
 
      # Returns the number of sons to keep. Looks for config values +:sons_to_keep+, 
      # +:son_promoted_on+. Default +14+.
      def sons_to_keep
        c[:sons_to_keep]    || c[:son_promoted_on]    || 14
      end
      
      # Returns the number of fathers to keep. Looks for config values +:fathers_to_keep+, 
      # +:fathers_promoted_on+. Default +6+.
      def fathers_to_keep
        c[:fathers_to_keep] || c[:father_promoted_on] || 6
      end

      # Returns the number of grandfathers to keep. Looks for config values
      # +:grandfathers_to_keep+. Default +6+.
      def gfathers_to_keep
        c[:grandfathers_to_keep] || 6
      end

      # This method returns the number of how many to keep in whatever today
      # goes in. Example: if today is a day to create a +son+ then this
      # function returns the value of +sons_to_keep+. If today is a +father+
      # then +fathers_to_keep+ etc.
      def how_many_to_keep_today
        goes_in = todays_generation
        keep = goes_in =~ /^sons$/         ? sons_to_keep     :
               goes_in =~ /^fathers$/      ? fathers_to_keep  :
               goes_in =~ /^grandfathers$/ ? gfathers_to_keep : 14
      end

   end
end
