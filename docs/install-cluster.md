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
- Create the command for the creator script. The proper syntax can be found
  by looking at the top of the `creator.sh` script. Below, we are creating PVs
  0 - 4999, each w/ a 1 GB quota.
  ```shell
  $ cd /mnt/supervole1b00
  $ /home/ec2-user/gluster-subvol/volcreator/creator.sh 192.168.20.11:192.168.20.12:192.168.20.13 supervole1b00 /mnt/supervole1b00 1 0 4999 | sudo tee creator_cmd_0_4999
  ```
- Run the command. This will take 5 -- 6 hours to run.
  ```shell
  $ sudo /home/ec2-user/gluster-subvol/volcreator/creator.sh 192.168.20.11:192.168.20.12:192.168.20.13 supervole1b00 /mnt/supervole1b00 1 0 4999
  ```
- Once the command completes, verify that all quotas have been properly
  created.
  ```shell
  $ sudo gluster vol quota supervole1b00 list | wc -l
  5002   # <-- 5000 quotas + 2 header lines
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
