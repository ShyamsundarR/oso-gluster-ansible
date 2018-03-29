[![Build Status](https://travis-ci.org/JohnStrunk/oso-gluster-ansible.svg?branch=master)](https://travis-ci.org/JohnStrunk/oso-gluster-ansible)

# Running playbooks

The playbooks in this repo can conveniently be run either with the
`ansible-vagrant` or `ansible-ec2` scripts depending on whether the playbook
should be run against the live environment or the Vagrant virtual one.

# Playbook structure

The top-level playbook is `site.yml`. In theory, this playbook can be run to
recreate the environment.

The `site.yml` playbook just includes lower-level playbooks from the
`playbook/` directory. The sub-playbooks are probably what you want for running
various tasks in the cluster.

Sub-playbooks:
- `create-gluster-ca.yml` - Generates a Gluster CA key/cert. This is a one-time
  operation, and is just here to document the process. The actual CA key
  material for the production cluster is stored outside this repo.
- `install-servers.yml` - This installs the Gluster server onto all inventory
  hosts in the `gluster-servers` group. This should only need to be run when
  new servers are added to the inventory.
- `gluster-volume.yml` - This creates volumes (supervols) on the servers. The
  configuration for the volumes can be found in `group_vars/gluster-servers`.
  This playbook will not destroy an existing volume, but may modify it, so be
  careful when editing the `gluster_volumes` dict.

# Inventory structure

The structure of the ansible groups is:
- gluster-servers  // from `inventory_groups`
  - *server cluster*  // from `inventory_groups` (e.g., us-east-2-c00)
    - *server group*  // from ec2 tags (e.g., `gluster-group=us-east-2-c00-g00`)

The Gluster server ec2 instances each have a tag, `gluster-group`, applied to
them to indicate which server group they are a part of. We are defining a
server group as a set of 3 servers, each in a different AZ. A group will be
used to create one or more replica 3 volumes. The `ec2.py` dynamic inventory
script uses the tag to create a host group as:
`tag_gluster_group_us_east_2_c00_g00`. We manually combine these dynamic groups
into clusters and add the clusters to the overall gluster-servers group. Both
of these are done in the `inventory_groups` file.

For each cluster, there is one instance that contains a tag designating it as
the "cluster master." While not really a "master," it is used as the host for
issuing gluster management cli commands. We do this instead of just `run_once:
true` because we need to make sure we can correctly assemble a single cluster
w/ peer probe, and the cli can have a locking problem w/ commands arriving from
many hosts.

# Vagrant environment

There is a vagrant environment in this repo that allows (manual) testing of the
ansible playbooks. You will need to bring your own RHEL 7.4 Vagrant box,
however. The `Vagrantfile` points to an initial ansible playbook and sets
inventory variables such that the VMs should be in groups and configurable just
like the corresponding AWS instances.

# AWS environment

To properly run against AWS, you need to have your credentials set properly. The
configuration assumes you have a boto profile named `osio` configured. Before
trying to run the ansible scripts, run `ec2.py` by itself and ensure it returns
suitable inventory information.

# Adding hardware to the environment

When new instances are to be added to the AWS environment, the inventory files
need to be adjusted to reflect how they should be grouped and configured.

If adding new servers, they should be tagged, as described above, with a server
"group." Since servers are added in multiples of the group size (3), you will be
adding a new group, most likely to an existing cluster. Just use the next
available group number in the tag. If you decided to start a new cluster, be
sure to tag one of the servers with the `cluster-master` tag. The new group (and
cluster) need to be added to the `inventory_groups` file so that the group is
part of the correct cluster and the (new) cluster is part of the overall
`gluster-servers`. The servers will need to be registered via
`register-servers.yml` and installed via `playbooks/install-servers.yml`. You
will probably want to limit the hosts to the new group to speed things along
when you run the playbook.

When adding additional volumes, that is done in the `group_vars/gluster-servers`
file. This file contains the definition for all volumes in all clusters. Just
add a new volume to the list here, specifying its size, the device to use, and
the name of the server group it should be created in. The
`playbooks/gluster-volume.yml` playbook can take it from there.
