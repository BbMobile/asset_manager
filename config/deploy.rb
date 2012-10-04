require 'capistrano_colors'

capistrano_color_matchers = [
  { :match => /command finished/,       :color => :hide,      :prio => 10 },
  { :match => /executing command/,      :color => :blue,      :prio => 10, :attribute => :underscore },
  { :match => /^transaction: commit$/,  :color => :magenta,   :prio => 10, :attribute => :blink },
  { :match => /git/,                    :color => :white,     :prio => 20, :attribute => :reverse },
]

colorize( capistrano_color_matchers )

# =========================================================================
# CONFIGURATION
# =========================================================================

# =======================================================================
# Application Properties
# =======================================================================
set :application, "asset_manager"

load 'config/shared/config'
load 'config/shared/custom_config'

namespace :deploy do

  task :default do
    sudo 'ls -larth'

  end

end