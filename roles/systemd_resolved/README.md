Ansible Role: systemd\_resolved
===============================

Ansible role to configure systemd-resolved.

Role Variables
--------------

```yaml
# enable or not systemd_resolved
systemd_resolved_enable_resolved: true

# links /etc/resolv.conf to /run/systemd/resolve/stub-resolv.conf
systemd_resolved_symlink_resolv_conf: true
```

License
-------

Tool under the BSD license. Do not hesitate to report bugs, ask me some
questions or do some pull request if you want to!
