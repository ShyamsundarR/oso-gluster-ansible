# -*- mode: ruby -*-
# vi: set ft=ruby :

STORAGENODES = 3
DISKS_PER_NODE = 3
DISKSIZE = '30G'

# Note: libvirt provider options:
#   https://github.com/vagrant-libvirt/vagrant-libvirt#provider-options

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"

  config.vm.provider "libvirt" do |provider|
    provider.cpus = "2"
    provider.memory = "1024"
  end

  config.vm.synced_folder ".", "/vagrant", disabled: true

  (0..STORAGENODES-1).each do |i|
    config.vm.define "gluster-#{i}" do |node|
      node.vm.hostname = "gluster-#{i}"
      node.vm.provider "libvirt" do |provider|
        for d in 0..DISKS_PER_NODE-1 do
          provider.storage :file, :size => DISKSIZE
        end
      end
      # Only set up provisioning on the last worker node so ansible only gets
      # called once during the provisioning step.
      if i == STORAGENODES-1
        node.vm.provision :ansible do |ansible|
          #ansible.extra_vars = {
          #  "master_ip" => MASTER_IP
          #}
          ansible.groups = {
            "gluster-servers" => (0..STORAGENODES-1).map {|j| "gluster-#{j}"}
          }
          ansible.limit = "all"
          ansible.playbook = "playbooks/ping.yml"
          #ansible.verbose = true
        end
      end
    end
  end
end
