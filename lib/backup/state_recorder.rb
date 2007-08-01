require 'fileutils'

class StateRecorder
  attr_accessor :sons_since_last_promotion
  attr_accessor :fathers_since_last_promotion
  attr_accessor :saved_state_folder

  def initialize
    @sons_since_last_promotion     = 0
    @fathers_since_last_promotion  = 0
  end

  # cleanup all the snapshots created by madeline
  def cleanup_snapshots
    files = Dir[saved_state_folder + "/*.snapshot"] 
    files.pop
    files.sort.each do |f|
      FileUtils.rm(f, :verbose => false)
    end
  end
end
