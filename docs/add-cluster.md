# Adding a new cluster to the playbooks

## Prerequisites
- The ec2 instances should be created and running in the AWS account
- The ec2 instances should be properly tagged
  - This includes instances being tagged with `gluster_group` to designate their
    server group as well as one from each cluster being tagged as the master via
    `gluster_master`

## Ansible configuration

- Update `inventory_groups`
  - Include the "group" tagged hosts into cluster groups.
  - Assign the `cluster_master` variable for each cluster
  - Add all new clusters as a child of `gluster-servers`

  For example, the following are for east-1b:
  ```yaml
  #-- 1b cluster 00
  [g-us-east-1b-c00:vars]
  cluster_master="{{ groups['tag_gluster_master_us_east_1b_c00'][0] }}"
  cluster_member_group="g-us-east-1b-c00"

  [g-us-east-1b-c00:children]
  tag_gluster_group_us_east_1b_c00_g00

  #-- 1b cluster 01
  [g-us-east-1b-c01:vars]
  cluster_master="{{ groups['tag_gluster_master_us_east_1b_c01'][0] }}"
  cluster_member_group="g-us-east-1b-c01"

  [g-us-east-1b-c01:children]
  tag_gluster_group_us_east_1b_c01_g00

  ...
  [gluster-servers:children]
  # List all clusters as children of gluster-servers
  ...
  g-us-east-1b-c00
  g-us-east-1b-c01
  ...
  ```

- Update `group_vars/gluster-servers` with the definitions for the cluster's
  supervol(s)

  For example:
  ```yaml
  # Defines the volumes exported by gluster
  gluster_volumes:
  ...
    supervole1b00:
      size: 500G
      device: /dev/xvdb
      group: tag_gluster_group_us_east_1b_c00_g00
    supervole1b01:
      size: 500G
      device: /dev/xvdb
      group: tag_gluster_group_us_east_1b_c01_g00
  ...
  ```

- Add dummy entries to `Vagrantfile` for the newly defined groups to prevent
  errors.

  For example:
  ```ruby
  ...
  "tag_gluster_master_us_east_1b_c00" => ["dummy"],
  "tag_gluster_group_us_east_1b_c00_g00" => ["dummy"],
  "tag_gluster_master_us_east_1b_c01" => ["dummy"],
  "tag_gluster_group_us_east_1b_c01_g00" => ["dummy"]
  ...
  ```
