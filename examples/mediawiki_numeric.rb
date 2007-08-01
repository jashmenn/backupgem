#------------------------------------------------------------------------------
# Mediawiki Backup script
# Uses numeric rotation instead of temporal
# @author: Nate Murray <nate@natemurray.com>
#------------------------------------------------------------------------------
action(:content) do 
  dump = c[:tmp_dir] + "/test.sql"
  sh "mysqldump -uroot test > #{dump}"
  dump
end

set :rotation_mode,              :numeric # base our rotation on numbers not dates
set :sons_promoted_after,        3        # upgrade to father after 3 sons 
set :fathers_promoted_after,     1 





