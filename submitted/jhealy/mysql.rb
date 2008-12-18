#------------------------------------------------------------------------------
# Mysql Backup script
# @author: James Healy <jimmy@deefa.com>
#------------------------------------------------------------------------------
action(:content) do 
  dump = c[:tmp_dir] + "/mysql.sql"
  sh "mysqldump --all-databases -uroot > #{dump}"
  dump
end

action :deliver, :method => :scp

action(:compress) do
  sh "gzip -f9 #{last_result}"
  "#{last_result}.gz"
end


action :rotate, :method => :via_ssh

