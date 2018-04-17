# Synchs vra appliance to domain
# Run this if the appliance is out of synch with IaaS components
service ntp stop
ntpdate -s cloudstackx.local
service ntp start
