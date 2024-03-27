# stackhpc.linux.iommu

## Example playbook

```
---
- name: Enable GPU Passthrough
  hosts: gpu_passthrough
  tasks:
    - import_role:
      name: stackhpc.linux.gpu_passthrough
  handlers:
    - name: reboot
      fail:
        msg: "Please reboot your hypervisor and re-run your host configure to continue"
      become: true

```

Or if you want the machine to reboot automatically:

```
---
- name: Enable GPU Passthrough
  hosts: gpu_passthrough
  tasks:
    - import_role:
      name: stackhpc.linux.gpu_passthrough
  handlers:
    - name: reboot
      reboot:
      become: true

```
