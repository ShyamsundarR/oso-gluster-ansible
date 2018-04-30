# Upgrading Gluster servers

This document outlines procedures for upgrading the packages on Gluster servers.

## Type of upgrade

Before upgrading, it is necessary to decide how extensively packages will be
updated. There are several options:

- All packages can be upgraded via: `sudo yum update`
- Only security fixes can be applied via: `sudo yum update --security`

__General advice:__ If Gluster or the kernel is going to be upgraded, it will
entail stopping Gluster, and a reboot at the end. In this case, go ahead and
fully upgrade the server (all packages).

## Upgrade procedure

- Determine if what is going to be upgraded: Run `sudo yum updateinfo list sec`
  for security-only updates or `sudo yum updateinfo list` for all. If the
  desired update type includes any kernel or Gluster packages, the above advice
  applies.
- Pre-flight
  - Ensure all bricks are online: `sudo gluster vol status` should show pids for
    all bricks in each volume
  - Ensure all volumes are fully healed: `sudo gluster vol heal <volname> info`
    should be run for each volume on that server. The output should show no
    pending entries and all bricks should be "connected." Example:

    ```shell
    $ sudo gluster vol heal supervol00 info
    Brick ip-192-168-0-11.us-east-2.compute.internal:/bricks/supervol00/brick
    Status: Connected
    Number of entries: 0

    Brick ip-192-168-0-13.us-east-2.compute.internal:/bricks/supervol00/brick
    Status: Connected
    Number of entries: 0

    Brick ip-192-168-0-12.us-east-2.compute.internal:/bricks/supervol00/brick
    Status: Connected
    Number of entries: 0
    ```

- Upgrade
  - If gluster packages are going to be upgraded, stop Gluster on this node:

    ```shell
    $ sudo systemctl stop glusterd
    $ sudo pkill glusterfs
    $ sudo pkill glusterfsd
    ```

  - Perform the update:

    ```shell
    $ sudo yum update
    # ... or ...
    $ sudo yum update --security
    ```

  - If the kernel or Gluster was updated, ensure Gluster is stopped (see above)
    and reboot:

    ```shell
  # Gluster should already be stopped!
    $ sudo shutdown -r now
    ```

- Post
  - Recheck gluster and wait for pending heals to complete

    ```shell
    $ sudo gluster vol status
    $ sudo gluster vol heal <volname> statistics heal-count
    # ... repeat above until the count is low ...
    $ sudo gluster vol heal <volname> info
    ```

The above steps should be repeated for each server in a cluster.
