#------------------------------------------------------------------------------
# Global Settings for Backup 
# This file sets the global settings for all recipes in the same directory
# @author: James Healy <jimmy@deefa.com>
#------------------------------------------------------------------------------

# This file specifies many, but not all, of the setting you can change for Backup.
# Any setting that is set to the default is commented out. Uncomment and
# change any to your liking.

# A single or array of servers to execute the backup tasks on
set :servers, %w{ ripsaw }  # default: localhost

# The directory to place the backup on the backup server
set :backup_path, "/home/nathan/tmp"

# Name of the SSH user
set :ssh_user, "nathan"

# Path to your SSH key
set :identity_key, "/Users/nathan/.ssh/id_rsa"

set :tmp_dir, "/tmp"

# rotation settings
set :son_promoted_on,    :sun
set :father_promoted_on, :last_sun_of_the_month

set :sons_to_keep,         21
set :fathers_to_keep,      12
set :grandfathers_to_keep, 12
