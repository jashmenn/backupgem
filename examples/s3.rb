#------------------------------------------------------------------------------
# Example S3 Backup script
# @author: Jason L. Perry <jasper@ambethia.com>
#------------------------------------------------------------------------------

# Set the name of the s3 bucket you want to store your backups in.
# Your Access ID is prepended to this to avoid naming conflicts.
set :backup_path, "database_backup" 

# You can specify your keys here, or set them as environment variables:
# AMAZON_ACCESS_KEY_ID
# AMAZON_SECRET_ACCESS_KEY
set :aws_access, '123'
set :aws_secret, 'ABC'

# S3 does not support renaming objects, so rotation data is stored in an
# index. You can specify a different key for index here, if you need to.
#
# set :rotation_object_key, 'backup_rotation_index.yml'

action(:content) do
  dump = c[:tmp_dir] + "/databases.sql" 
  sh "mysqldump -uroot --all-databases > #{dump}" 
  dump
end

action :deliver,  :method => :s3
action :rotate,   :method => :via_s3

set :son_promoted_on,    :fri
set :father_promoted_on, :last_fri_of_the_month

set :sons_to_keep,         7  
set :fathers_to_keep,      5
set :grandfathers_to_keep, 12
