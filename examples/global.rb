#------------------------------------------------------------------------------
# Global Settings for Backup 
# This file sets the global settings for all recipes in the same directory
# @author: Nate Murray <nate@natemurray.com>
#------------------------------------------------------------------------------

# This file specifies many, but not all, of the setting you can change for Backup.
# Any setting that is set to the default is commented out. Uncomment and
# change any to your liking.

# A single or array of servers to execute the backup tasks on
# set :servers,             %w{ localhost someotherhost }  # default: localhost

# The directory to place the backup on the backup server
set :backup_path, "/var/local/backups/mediawiki"

# Name of the SSH user
# set :ssh_user,            ENV['USER']

# Path to your SSH key
# set :identity_key,        ENV['HOME'] + "/.ssh/id_rsa"

# Set global actions
# action :compress, :method => :tar_bz2   # tar_bz2 is the default
# action :deliver,  :method => :mv        # mv is the default
# action :encrypt,  :method => :gpg       # gpg is the default

set :tmp_dir, File.dirname(__FILE__) + "/../tmp"
