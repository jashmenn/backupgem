class Time
  def days_since_epoch
    self.to_i / 60 / 60 / 24
  end

  def self.num_from_day(day)
    days = { :sun => 0,
             :mon => 1,
             :tue => 2,
             :wed => 3,
             :thu => 4,
             :fri => 5,
             :sat => 6}
    days[day]
  end
end
