require 'rubygems'        # if you use RubyGems
require 'daemons'

Daemons.run('myserver.rb')

# ruby myserver_control.rb start
# ruby myserver_control.rb restart
# ruby myserver_control.rb stop