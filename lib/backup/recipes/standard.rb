#------------------------------------------------------------------------------
# Backup Global Settings
# @author: Nate Murray <nate@natemurray.com>
#   @date: Mon Aug 28 07:28:22 PDT 2006
# 
# The settings contained in this file will be global for all tasks and can be
# overridden locally.
#------------------------------------------------------------------------------

# Sepcify sever settings
set :servers,           %w{ localhost }
set :action_order,      %w{ content compress encrypt deliver rotate cleanup }

# Name of the SSH user
set :ssh_user,          ENV['USER']

# Path to your SSH key
set :identity_key,      ENV['HOME'] + "/.ssh/id_rsa"

# Set global actions
action :compress, :method => :tar_bz2 
action :deliver,  :method => :mv    
#action :encrypt,  :method => :gpg

# Specify a directory that backup can use as a temporary directory
set :tmp_dir, "/tmp"

# These settings specify the rotation variables
# Rotation method. Currently the only method is gfs, grandfather-father-son. 
# Read more about that below
set :rotation_method,  :gfs

# Rotation week starts on 
set :week_starts_on,   :mon

# Promote Backups to the next level (son to father, father to grandfather) on
# this day
set :promote_on,       :fri
set :dont_backup_on,    %q{sat sun}

# These options specify how many days there are in the cycle for each of the
# tiers.  Under these settings we will keep daily backups (sons) for two weeks.
# Then at the end of the two weeks (on day 14) we will promote the son to
# 'father'. On the 4th father that is created (on day 56 [= 14*4]) we will
# promote to grandfather. We keep 6 old grandfathers.
set :son_promoted_on,      14   # two weeks 
set :father_promoted_on,    4   # every two months (56 days)
set :grandfathers_to_keep,  6   # 6 months


# -------------------------
# Standard Actions
action(:tar_bz2) do
  name = c[:tmp_dir] + "/" + File.basename(last_result) + ".tar.bz2"
  puts "tar -cvjf #{name} #{last_result}"
  name
end

action(:scp) do
  # what should the default scp task be?
  # scp the local file to the foreign directory. same name.
  c[:servers].each do |server|
    puts "scp #{last_result} #{server}:#{c[:backup_path]}/"
  end
  last_result
end

action(:mv) do
  puts last_result
  puts "mv #{last_result} #{c[:backup_path]}/"
  # backup_path + "/" + last_result
  c[:backup_path] + "/" + last_result
end


# TODO - make it so that the 'set' variables are available to these actions
# without having to access the config array.
