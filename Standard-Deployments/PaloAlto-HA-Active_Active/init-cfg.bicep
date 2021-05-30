var init = '''
type=dhcp-client
ip-address=
default-gateway=
netmask=
ipv6-address=
ipv6-default-gateway=
hostname=
vm-auth-key=
panorama-server=
panorama-server-2=
tplname=
dgname=
dns-primary=168.63.129.16
dns-secondary=
op-command-modes=
op-cmd-dpdk-pkt-io=
dhcp-send-hostname=yes
dhcp-send-client-id=yes
dhcp-accept-server-hostname=yes
dhcp-accept-server-domain=yes
'''

output cfg string = init
