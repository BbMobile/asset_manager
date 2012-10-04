default_run_options[:pty] = true  # Must be set for the password prompt
                                  # from git to work

set :scm, "git"
set :deploy_via, :remote_cache
set :deploy_to, "/usr/local/asset_manager"