stackhpc.linux.sriov
==============

[![Build Status](https://travis-ci.com/stackhpc/ansible-role-sriov.svg?branch=master)](https://travis-ci.com/stackhpc/ansible-role-sriov)

Ansible role to enable SR-IOV on network devices.

Requirements
------------
None

Role Variables
--------------

See `defaults/main.yml`

Dependencies
------------

- `stackhpc.linux.grubcmdline`

Example Playbook
----------------

```
- name: configure sr-iov
  hosts: compute
  vars:
    sriov_devices:
      - name: p4p1
        numvfs: 63
      - name: p3p1
        numvfs: 8
        # Don't add a udev rule to set numvfs. This can be useful if you use an alternative method
        # to set the number of virtual functions e.g some custom scripts to enable VFLAG, but want
        # to use the role to set firmware parameters.
        on_boot_configuration_enabled: false
  tasks:
    - include_role:
        name: sriov
  handlers:
    - name: reboot
      include_tasks: tasks/reboot.yml
```

License
-------

Apache2

Author Information
------------------

Will Szumski
