require 'rubygems'        # if you use RubyGems
require 'daemons'

Daemons.run('EM_UDP_KidsThrow.rb')

# ruby myserver_control.rb start
# ruby myserver_control.rb restart
# ruby myserver_control.rb stop