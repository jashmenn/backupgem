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

      goes_in = today_goes_in
      place_in = c[:backup_path] + "/" + goes_in  

      # place todays backup into the specified directory with a timestamp. 
      newname = timestamped_prefix(last_result)
      sh "mv #{last_result} #{place_in}/#{newname}"

      cleanup_via_mv(place_in, how_many_to_keep_today)
    end
    
    def rotate_via_ssh(last_result)
      # copy the model supplied above. take everything out and make it a private method.
      # al the stuff about what goes where today etc can all be methods. 
      # test against yourself.
      #
      # this is the last part of this script. we're almost finished
    end

    def rotate_via_ftp(last_result)
    end

    def promote_sons_today?
      offset_days % c[:son_promoted_on] == 0 ? true : false
    end

    def promote_fathers_today?
      offset_days % (c[:son_promoted_on] * c[:father_promoted_on]) == 0 ? true : false
    end

    private
      def verify_local_backup_directory_exists(dir)
        path = c[:backup_path]
        full = path + "/" + dir
        unless File.exists?(full) 
          sh "mkdir -p #{full}"  
        end
      end

      def offset_days
        t = ENV['TEST_TIME'] || Time.now # todo, write a test to use this
        num_from_day = Time.num_from_day( c[:promote_on] )
        #t.days_since_epoch + num_from_day - 6 
        t.days_since_epoch + num_from_day - 3  # TODO - test this. is this working the way we want?
      end

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

      # figure out where today's backup should go
      def today_goes_in
        goes_in = promote_fathers_today? ? "grandfathers" :         \
                  promote_sons_today?    ? "fathers"      : "sons"
      end

      # Given +name+ returns a timestamped version of name. 
      def timestamped_prefix(name)
        newname = Time.now.strftime("%Y-%m-%d-%H-%M-%S_") + File.basename(name)
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
        goes_in = today_goes_in
        keep = goes_in =~ /^sons$/         ? sons_to_keep     :
               goes_in =~ /^fathers$/      ? fathers_to_keep  :
               goes_in =~ /^grandfathers$/ ? gfathers_to_keep : 14
      end

   end
end
