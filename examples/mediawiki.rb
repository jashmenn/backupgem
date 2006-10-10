#------------------------------------------------------------------------------
# Mediawiki Backup script
# @author: Nate Murray <nate@natemurray.com>
#------------------------------------------------------------------------------
action(:content) do 
  dump = c[:tmp_dir] + "/test.sql"
  sh "mysqldump -uroot test > #{dump}"
  # should something happen here to cleanup the last task? maybe something
  # should happen to the stack. like if the next task goes through then you
  # remove he last file from the stack. Ah. if everything goes well you clean
  # up everything from the stack. 
  dump
end

# action :compress, :method => :tar_bz2   # could be set in global
# action :deliver,  :method => :scp       # could be set in global

# settings for backup servers are global unless specified otherwise
# rotate settings are global unless specified herer





