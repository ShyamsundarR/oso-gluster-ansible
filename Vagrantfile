# -*- mode: ruby -*-
# vi: set ft=ruby :

NODES = 6
DISKS_PER_NODE = 1
DISKSIZE = "50G"

Vagrant.configure("2") do |config|
  config.vm.box = "rhel-svr-7.4-reg"
  config.vm.provider "libvirt" do |lv|
    lv.cpus = "2"
    lv.memory = "1024"
    lv.nested = true
    lv.volume_cache = "none"
  end

  # Can't write to /vagrant on atomic-host, so disable default sync dir
  config.vm.synced_folder ".", "/vagrant", disabled: true

#  config.vm.define "master" do |node|
#    node.vm.hostname = "master"
#    # master gets this repo synced to /vagrant
#    #node.vm.synced_folder ".", "/vagrant", type: "sshfs"
#  end

  (0..NODES-1).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "node#{i}"
      node.vm.provider "libvirt" do |provider|
        for d in 0..DISKS_PER_NODE-1 do
          provider.storage :file, :size => DISKSIZE
        end
      end
      # Only set up provisioning on the last worker node so ansible only gets
      # called once during the provisioning step.
      if i == NODES-1
        node.vm.provision :ansible do |ansible|
          # https://www.vagrantup.com/docs/provisioning/ansible_intro.html
          #ansible.extra_vars = {
          #  "ansible_become" => "true"
          #}
          #ansible.host_vars = {
          #  "host1" => {"http_port" => 80,
          #              "maxRequestsPerChild" => 808},
          #  "host2" => {"http_port" => 303,
          #              "maxRequestsPerChild" => 909}
          #}
          ansible.groups = {
            # mimics AWS dynamic inventory generated group based on instance
            # tag of gluster-master=us-east-2-c00
            "tag_gluster-master_us-east-2-c00" => ["node1"],
            # ec2 tag: gluster-group=us-east-2-c00-g00
            "tag_gluster-group_us-east-2-c00-g00" => [
              "node0",
              "node1",
              "node2"
            ],
            # ec2 tag: gluster-group=us-east-2-c00-g01
            "tag_gluster-group_us-east-2-c00-g01" => [
              "node3",
              "node4",
              "node5"
            ]
          }
          ansible.limit = "all"
          ansible.playbook = "vagrant.yml"
          #ansible.verbose = true
        end
      end
    end
  end
end
