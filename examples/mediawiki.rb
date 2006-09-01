#------------------------------------------------------------------------------
# Mediawiki Backup script
# @author: Nate Murray <nate@natemurray.com>
#------------------------------------------------------------------------------
action(:content) do 
  puts "Creating the mediawiki sql"
  puts last_result.inspect
  sh "echo Creating mysql dump"
  #sh "mysqldump -uroot database > /tmp/mediawiki.sql"
  #"/tmp/mediawiki.sql" # return the full path to the folder/file of the content
  "foobar"
end

action(:before_content) do
  puts "wait before content!"
  "smashing"
end

action(:after_compress) do
 puts "we are done compressing"
 puts result_history.inspect
end

action(:tar_bz2) do
  puts "we are tar_bz2'ing"
  "Tar_bzd"
end

action :compress, :method => :tar_bz2   # could be set in global
# action :delivery, :method => :scp       # could be set in global

# settings for backup servers are global unless specified otherwise
# rotate settings are global unless specified herer





