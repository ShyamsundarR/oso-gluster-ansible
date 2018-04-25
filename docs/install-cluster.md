# Steps for installing a new cluster

## Installing gluster on the servers
- Make sure you can ping the new machines to be installed:
  ```shell
  ./ansible-ec2 -l cluster1,cluster2 ping.yml
  ```
- Register the servers w/ subscription manager and update (Warning: this will
  reboot all servers in the list):
  ```shell
  ./ansible-ec2 -l cluster1,cluster2 register-servers.yml
  ```
- Install the servers.  
  While it is possible to do this by directly running `site.yml`, it is
  recommended that the sub-playbooks be run individually to more easily
  supervise the process. (current list follows)
  ```shell
  ./ansible-ec2 -l cluster1,cluster2 playbooks/ssh-keys.yml
  ./ansible-ec2 -l cluster1,cluster2 playbooks/install-servers.yml
  ./ansible-ec2 -l cluster1,cluster2 playbooks/gluster-volume.yml
  ./ansible-ec2 -l cluster1,cluster2,pcp-aggregators playbooks/install-jumphost.yml
  ```

## Creating the subvol PVs
- Log into the 'master' machine for the cluster
- Start screen (this will take a while to run):
  ```shell
  $ screen -xR
  ```
- Check out the subvol code:
  ```shell
  $ git clone https://github.com/gluster/gluster-subvol.git
  ```
- Mount the volume on the host:
  ```shell
  $ sudo gluster vol list
  gluster_shared_storage
  supervole1b00
  $ sudo mkdir /mnt/supervole1b00
  $ sudo mount -tglusterfs localhost:/supervole1b00 /mnt/supervole1b00
  ```
- Run the command for the creator script. The proper syntax can be found by
  looking at the top of the `creator_xfs_quota.sh` script. Below, we are
  creating PVs 0 - 4999, each w/ a 1 GB quota.
  ```shell
  $ cd /mnt/supervole1b00
  $ sudo /home/ec2-user/gluster-subvol/volcreator/creator_xfs_quota.sh 172.31.80.251:172.31.87.134:172.31.93.163 supervole1b00 /mnt/supervole1b00/ 1 0 4999
  ```
- The above command will create 2 files:
  - `pvs-0-4999.yml`, which is the PV descriptions
  - `quota-0-4999.dat`, which is the description of the quotas to apply to the
    bricks
- On each brick server, apply the quotas by providing the brick directory and
  the quota file to the `apply_xfs_quota.sh` script
  ```shell
  $ sudo /home/ec2-user/gluster-subvol/volcreator/apply_xfs_quota.sh /bricks/supervole1b00/brick /mnt/supervole1b00/quota-0-4999.dat
  ```
- Once the command completes, verify that all quotas have been properly
  created.
  ```shell
  $ sudo xfs_quota -x -c 'report -p -a'
  ```
- Copy the yaml file that contains the PV description to your local machine.
  You will need to use `scp` through the jump host. Assuming the jump host is
  `1.2.3.4` and the server we are working with is `192.168.20.11`, from your
  local machine:
  ```shell
  $ scp -o ProxyCommand="ssh -W %h:%p -q ec2-user@1.2.3.4" ec2-user@192.168.20.11:/mnt/supervole1b00/pvs-0-4999.yml .
  ```

## Next steps
- Package up the PV descriptions, recycler config, and TLS keys. These need
  to be sent to the Online team so that the OpenShift side can be deployed.
- Make sure the newly provisioned hosts are reporting into Zabbix properly
- Check back in a couple days and make sure snapshots are working properly.
  ```shell
  $ sudo gluster snap list
  ```
