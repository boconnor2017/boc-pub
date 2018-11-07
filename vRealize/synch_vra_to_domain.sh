# Synchs vra appliance to domain
# Run this if the appliance is out of synch with IaaS components
service ntp stop
ntpdate -s pool.ntp.org
service ntp start
