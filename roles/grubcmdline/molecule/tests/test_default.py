import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_kernel_cmdline(host):
    f = host.file('/etc/default/grub')
    assert f.exists
    assert f.user == 'root'
    assert f.group == 'root'
