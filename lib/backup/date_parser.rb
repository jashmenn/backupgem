module Backup
  class DateParser

    def self.date_from(what)
      DateParser.new.date_from(what)
    end

    # the test is going to be whatever is returned here .include? the day of
    # today. so if we want to do something every day than this needs to return
    # something that will lincde the righ daY:W
    def date_from(what) 
      if what.kind_of?(Symbol)
        return Runt::DIWeek.new( Time.num_from_day(what) ) if day_of_week?(what) 
        return Runt::REDay.new(0,0,24,01) if what == :daily
        if what.to_s =~ /^last_/
          what.to_s =~ /^last_(\w+)_of_the_month$/
          day = $1
          return Runt::DIMonth.new(Runt::Last, Time.num_from_day(day.intern))
        end
      end
      raise "#{what} is not a valid time" unless what.respond_to?(:include?)
      what
    end

    private
      def day_of_week?(word)
        days_of_week.include?(word.to_s.downcase[0..2])
      end

      def days_of_week
        %w{mon tue wed thu fri sat sun}
      end

  end
end


