stackhpc.grubcmdline
====================

Sets the default kernel command line

Requirements
------------

grub

Role Variables
--------------

Please see `defaults/main.yml`

Dependencies
------------

None

Example Playbook
----------------

```
- name: Enable huge pages
  hosts: compute-hugepages
  vars:
    kernel_cmdline:
      - transparent_hugepage=never
      - default_hugepagesz=2M
      - hugepagesz=2M
      - hugepages=184320
    kernel_cmdline_remove:
      - hugepage
  tasks:
    - include_role:
        name: stackhpc.grubcmdline
  handlers:
    - name: reboot
      include_tasks: tasks/reboot.yml
```

License
-------

Apache

Author Information
------------------

Will Szumski
