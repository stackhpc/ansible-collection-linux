# stackhpc.linux.vgpu

## Prerequisites

- [Download Nvidia GRID driver](https://docs.nvidia.com/grid/latest/grid-software-quick-start-guide/index.html#redeeming-pak-and-downloading-grid-software) (This requires a login).
    - The location of this file can be customised with the `vgpu_driver_url` variable:
      * e.g to use an artifact uploaded to a http server:
      `vgpu_driver_url: http://seed/pulp/content/nvidia/NVIDIA-GRID-Linux-KVM-525.85.07-525.85.05-528.24.zip`
      * e.g to use file the control host:
      `vgpu_driver_url: file://seed/pulp/content/nvidia/NVIDIA-GRID-Linux-KVM-525.85.07-525.85.05-528.24.zip`

- Enable IOMUU
    - Make sure the related options are enabled in the BIOS
    - Intel CPUs require the intel_iommu kernel command line argument

## Enabling SR-IOV on dell hardware

```
 /opt/dell/srvadmin/bin/idracadm7 set BIOS.IntegratedDevices.SriovGlobalEnable Enabled
 /opt/dell/srvadmin/bin/idracadm7 jobqueue create BIOS.Setup.1-1
```

## Running the role

Example playbook:

```
- hosts: compute_gpu_a100
  vars:
    nvidia_driver_url: "http://seed/pulp/content/nvidia/NVIDIA-GRID-Linux-KVM-525.85.07-525.85.05-528.24.zip"
  tasks:
    - import_role:
        name: stackhpc.linux.vgpu
```

Where the configuration is done using `group_vars`:

`group_vars/compute_a100/gpu`
```
#nvidia-692 GRID A100D-4C
#nvidia-693 GRID A100D-8C
#nvidia-694 GRID A100D-10C
#nvidia-695 GRID A100D-16C
#nvidia-696 GRID A100D-20C
#nvidia-697 GRID A100D-40C
#nvidia-698 GRID A100D-80C
#nvidia-699 GRID A100D-1-10C
#nvidia-700 GRID A100D-2-20C
#nvidia-701 GRID A100D-3-40C
#nvidia-702 GRID A100D-4-40C
#nvidia-703 GRID A100D-7-80C
#nvidia-707 GRID A100D-1-10CME
vgpu_definitions:
    # Configuring a MIG backed VGPU
    - pci_address: "0000:17:00.0"
      virtual_functions:
        - mdev_type: nvidia-700
          index: 0
        - mdev_type: nvidia-700
          index: 1
        - mdev_type: nvidia-700
          index: 2
        - mdev_type: nvidia-699
          index: 3
      mig_devices:
        "1g.10gb": 1
        "2g.20gb": 3
    # Configuring a card in a time-sliced configuration (non-MIG backed)
    - pci_address: "0000:65:00.0"
      virtual_functions:
        - mdev_type: nvidia-697
          index: 0
        - mdev_type: nvidia-697
          index: 1
```


Please see the [nvidia documentation on device profiles](https://docs.nvidia.com/datacenter/tesla/mig-user-guide/index.html#a100-profiles).

## Openstack configuration

### Kolla-ansible

Example `nova.conf` configuration:

```
{% if inventory_hostname in groups['compute_gpu_a100'] %}
[devices]
enabled_mdev_types = nvidia-700, nvidia-699, nvidia-697

[mdev_nvidia-700]
device_addresses = 0000:17:00.4,0000:17:00.5,0000:17:00.6
mdev_class = CUSTOM_NVIDIA_700

[mdev_nvidia-699]
device_addresses = 0000:17:00.7
mdev_class = CUSTOM_NVIDIA_699

[mdev_nvidia-697]
device_addresses = 0000:65:00.4,0000:65:00.5
mdev_class = CUSTOM_NVIDIA_697
{% endif %}
```

You will need to adjust the PCI addresses to match the virtual function addresses. These can
be obtained by checking the mdevctl configuration after running the role:

```
# mdevctl list
73269d0f-b2c9-438d-8f28-f9e4bc6c6995 0000:17:00.4 nvidia-700 manual (defined)
dc352ef3-efeb-4a5d-a48e-912eb230bc76 0000:17:00.5 nvidia-700 manual (defined)
a464fbae-1f89-419a-a7bd-3a79c7b2eef4 0000:17:00.6 nvidia-700 manual (defined)
f3b823d3-97c8-4e0a-ae1b-1f102dcb3bce 0000:17:00.7 nvidia-699 manual (defined)
330be289-ba3f-4416-8c8a-b46ba7e51284 0000:65:00.4 nvidia-697 manual (defined)
1ba5392c-c61f-4f48-8fb1-4c6b2bbb0673 0000:65:00.5 nvidia-697 manual (defined)
```

## Start up ordering of systemd services

The role will configure several systemd services. The start up ordering is detailed in this
section. NOTE: These are not steps you have to do manually.

### 1) Enable SRIOV on device

This must be done before applying mig configuration as it wipes out any mig configuration
that you may have applied.

Example of templated unit file:

```
[Unit]
Description=Enable SR-IOV on Nvidia card (0000:17:00.0)
Before=nvidia-mig-manager.service
DefaultDependencies=no
After=local-fs.target sys-devices-pci0000:16-0000:16:02.0-0000:17:00.0.device
Wants=sys-devices-pci0000:16-0000:16:02.0-0000:17:00.0.device

[Service]
Type=oneshot
User=root
# NOTE(wszumski): There is a race in the driver initialization where if we run this too early, then
# the mdev_support_devices entry doesn't show up in sysfs. I was unable to get this to show up again
# without a reboot.
ExecStartPre=/bin/sleep 5
ExecStart=/usr/lib/nvidia/sriov-manage -e 0000:17:00.0
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
RequiredBy=nvidia-mig-manager.service
```

There will be a unit file per card.

### 2) Apply MIG configuration

This is applied using nvidia-mig-manager. The config file can be found at the following path:

`/etc/nvidia-mig-manager/kayobe.yaml`. An example is shown below:

```
version: v1
mig-configs:
  default:
      # Annoying that this doesn't support pci addresses.
      - devices: [0]
        mig-enabled: true
        mig-devices: {"1g.10gb": 1, "2g.20gb": 3}
```

### 3) Start mdev device

It was originally envisaged that we could use the autostart feature of mdevctl. The issue
was that it was trying to start the mdev devices after we enabled SR-IOV, but before the
card had been sliced up using MIG. We are using a templated systemd unit file, which can
be found at the following path: `/etc/systemd/system/nvidia-mdev@.service`:

```
cat /etc/systemd/system/nvidia-mdev@.service
[Unit]
Description=Enable mdev device (%i)
After=nvidia-mig-manager.service
Before=docker.service
Requires=nvidia-mig-manager.service

[Service]
Type=oneshot
User=root
ExecStartPre=/bin/sleep 5
ExecStart=-/usr/sbin/mdevctl start --uuid %i
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

This is templated for each mdev device e.g:

```
systemctl status nvidia-mdev@330be289-ba3f-4416-8c8a-b46ba7e51284.service
● nvidia-mdev@330be289-ba3f-4416-8c8a-b46ba7e51284.service - Enable mdev device (330be289-ba3f-4416-8c8a-b46ba7e51284)
   Loaded: loaded (/etc/systemd/system/nvidia-mdev@.service; enabled; vendor preset: disabled)
   Active: active (exited) since Thu 2023-03-30 18:09:43 BST; 2 weeks 5 days ago
  Process: 2633 ExecStart=/usr/sbin/mdevctl start --uuid 330be289-ba3f-4416-8c8a-b46ba7e51284 (code=exited, status=0/SUCCESS)
  Process: 2212 ExecStartPre=/bin/sleep 5 (code=exited, status=0/SUCCESS)
 Main PID: 2633 (code=exited, status=0/SUCCESS)
    Tasks: 0 (limit: 3355442)
   Memory: 0B
   CGroup: /system.slice/system-nvidia\x2dmdev.slice/nvidia-mdev@330be289-ba3f-4416-8c8a-b46ba7e51284.service

Mar 30 18:09:38 myhost systemd[1]: Starting Enable mdev device (330be289-ba3f-4416-8c8a-b46ba7e51284)...
Mar 30 18:09:43 myhost systemd[1]: Started Enable mdev device (330be289-ba3f-4416-8c8a-b46ba7e51284).
```
