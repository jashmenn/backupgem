#------------------------------------------------------------------------------
# Backup Global Settings
# @author: Nate Murray <nate@natemurray.com>
#   @date: Mon Aug 28 07:28:22 PDT 2006
# 
# The settings contained in this file will be global for all tasks and can be
# overridden locally.
#------------------------------------------------------------------------------
require 'tmpdir'

# Sepcify sever settings
set :servers,           %w{ localhost }
set :action_order,      %w{ content compress encrypt deliver rotate cleanup }

# Name of the SSH user
set :ssh_user,          ENV['USER']

# default port
set :port,          22 # todo, change to ssh_port

# Path to your SSH key
set :identity_key,      ENV['HOME'] + "/.ssh/id_rsa"

# Set global actions
action :compress, :method => :tar_bz2 
action :deliver,  :method => :mv      # action :deliver,  :method => :scp    
action :rotate,   :method => :via_mv  # action :rotate,   :method => :via_ssh
# action :encrypt,  :method => :gpg

# Specify a directory that backup can use as a temporary directory
set :tmp_dir, Dir.tmpdir

# Options to be passed to gpg when encrypting
set :encrypt, false
set :gpg_encrypt_options, ""

# These settings specify the rotation variables
# Rotation method. Currently the only method is gfs, grandfather-father-son. 
# Read more about that below
set :rotation_method,  :gfs

# rotation mode - temporal or numeric. For instance
# temporal mode would continue to be the default and work with
# :son_promoted_on. The promotions are based on days. This works well for 1 backup per day.
# numeric works by promoting after every number of creations. This is better for multiple backups per day.
# numeric mode uses :sons_promoted_after
set :rotation_mode, :temporal

# :mon-sun
# :last_day_of_the_month # whatever son_promoted on son was, but the last of the month
# everything else you can define with a Runt object
# set :son_created_on,     :every_day - if you dont want a son created dont run the program
# a backup is created every time the program is run

set :son_promoted_on,    :fri
set :father_promoted_on, :last_fri_of_the_month

# more complex
# mon_wed_fri = Runt::DIWeek.new(Runt::Mon) | 
#               Runt::DIWeek.new(Runt::Wed) | 
#               Runt::DIWeek.new(Runt::Fri)
# set :son_promoted_on, mon_wed_fri

set :sons_to_keep,         14
set :fathers_to_keep,       6
set :grandfathers_to_keep,  6   # 6 months, by default

# These options are only used if :rotation_mode is :numeric.
# This is better if you are doing multiple backups per day.
# This setting says that every 14th son will be promoted to a father. 
set :sons_promoted_after,         14
set :fathers_promoted_after,       6

# -------------------------
# Standard Actions
# -------------------------
action(:tar_bz2) do
  name = c[:tmp_dir] + "/" + File.basename(last_result) + ".tar.bz2"
  v = "v" if verbose
  sh "tar -c#{v}jf #{name} #{last_result}"
  name
end

action(:scp) do
  # what should the default scp task be?
  # scp the local file to the foreign directory. same name.
  c[:servers].each do |server|
    host = server =~ /localhost/ ? "" : "#{server}:"
    sh "scp #{last_result} #{c[:ssh_user]}@#{host}#{c[:backup_path]}/"
  end
  c[:backup_path] + "/" + File.basename(last_result)  
end

action(:mv) do
  move last_result, c[:backup_path]  # has to be move (not mv) to avoid infinite
                                     # recursion
  c[:backup_path] + "/" + File.basename(last_result)
end

action(:s3) do
  s3 = S3Actor.new(c)
  s3.put last_result
end

action(:encrypt) do
  result = last_result
  if c[:encrypt]
    sh "gpg #{c[:gpg_encrypt_options]} --encrypt #{last_result}"
    result = last_result + ".gpg" # ?
  end
  result
end
