# stackhpc.linux.iommu

## Variables

- `iommu_pt`: Default true, Configure passthrough mode, which doesn't require DMA translation.

## Example playbook

```
---
- name: Enable IOMMU
  hosts: iommu
  tasks:
    - import_role:
      name: stackhpc.linux.iommu
  handlers:
    - name: reboot
      fail:
        msg: "Please reboot your hypervisor and re-run your host configure to continue"
      become: true

```

Or if you want the node to reboot automatically

```
---
- name: Enable IOMMU
  hosts: iommu
  tasks:
    - import_role:
      name: stackhpc.linux.iommu
  handlers:
    - name: reboot
      reboot:
      become: true

```
