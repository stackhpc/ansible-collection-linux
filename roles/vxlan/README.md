VXLAN
=========

This role creates persistent VXLAN interfaces with the use of [Network Scripts](https://pkgs.org/download/network-scripts), [NetworkManger](https://pkgs.org/download/NetworkManager), or [Systemd-Networkd](https://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html).

Role Variables
--------------

The role uses the same variable names as `Network Scripts`. It is recommended to review the documentation on [Network Scripts](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/s1-networkscripts-interfaces). Below are the variables relevant and supported by this role.

`vxlan_vni`: sets the VXLAN network identifier for the VXLAN interfaces

`vxlan_ttl`: set the time-to-live for the packets transmitted over the interface

`vxlan_phys_dev`: set the physical device for the VXLAN interface to pair with

`vxlan_dstport`: set the port for the VXLAN to reside on

`vxlan_bootproto`: specify boot protocol used with the interface (unsupported when using NetworkManger or Systemd-Networkd, always none)

`vxlan_onboot`: set to `yes` if the VXLAN interface should be brought up on boot otherwise `no` (Not supported on Systemd-networkd)

`vxlan_interfaces`: list of interfaces to be created can set specific instances of the variables defined above in addition to some others
> `device`: name assigned the VXLAN interface
>
> `ipaddr`: the IPV4 address assigned to the VXLAN interface (unsupported when using NetworkManger or Systemd-Networkd)
>
> `prefix`: the subnet mask use with the `ipaddr` (unsupported when using NetworkManger or Systemd-Networkd)
>
> `group`: the multicast group the VXLAN will operate on
>
> `bridge`: if set establish a bridge between this VXLAN and the specified interface

By default, Network Scripts will be used unless it is unavailable. Usage of either Network Scripts, NetworkManager or Systemd-Networkd can be enforced by setting `force_ns`, `force_nm`, or `force_sd` to true. 

Example Playbook
----------------

  Include the role into a playbook as you would any other role.

    - hosts: host1
      roles:
        - role: vxlan
          vars:
            vxlan_vni: 10
            vxlan_interfaces:
              - device: vxlan0
                ipaddr: 192.168.0.2
                group: 224.0.0.100


  For variables such as `vxlan_ipaddr` it is best to define them on a host by host basis.

  ### /host_vars/host1

    vxlan_interfaces:
      - device: vxlan0
        ipaddr: 192.168.0.2
        group: 224.0.0.100

  ### /host_vars/host2

    vxlan_interfaces:
      - device: vxlan0
        ipaddr: 192.168.0.3
        group: 224.0.0.100

You may also define multiple VXLAN interfaces per host however you must provide a unique `vxlan_vni` for each device defined in `vxlan_interfaces`

  ### /host_vars/host1

    vxlan_interfaces:
      - device: vxlan0
        vni: 10
        group: 224.0.0.200
      - device: vxlan1
        vni: 20
        group: 224.0.0.200

You may also set a bridge for vxlan interface to operate over.

  ### /host_vars/host1

    vxlan_interfaces:
      - device: vxlan0
        group: 224.0.0.10
        bridge: breth1

License
-------

Apache License 2.0

Author Information
------------------

[StackHPC](https://www.stackhpc.com/)
