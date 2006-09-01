#------------------------------------------------------------------------------
# Global Settings for Backup 
# This file sets the global settings for all recipes in the same directory
# @author: Nate Murray <nate@natemurray.com>
#------------------------------------------------------------------------------

# A single or array of servers to execute the backup tasks on
set :servers,             %w{ localhost someotherhost }

# The directory to place the backup on the foreign server
set :foreign_backup_path, "/var/backups/mediawiki"

# How you want to deliver your files.  Supported: mv, scp, ftp and the
# ability to define your own
set :delivery_protocol,   :scp  

# Name of the SSH user
set :ssh_user,            ENV['USER']

# Path to your SSH key
set :identity_key,        ENV['HOME'] + "/.ssh/id_rsa"

# Set global actions
action :compress, :method => :tar_bz2   # could be set in global
#action :delivery, :method => :scp       # could be set in global
#action :encrypt,  :method => :gpg

set :tmp_dir, File.dirname(__FILE__) + "/../tmp"
