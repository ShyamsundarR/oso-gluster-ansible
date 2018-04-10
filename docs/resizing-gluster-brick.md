# Resizing XFS mounts backing a gluster brick

This document details the operational procedure to expand a XFS filesystem that
is used to back the Gluster bricks, created using the ansible plays in this
repository.

**NOTE**: Prior to executing these instructions ensure that the LVM thin pool is
expanded using this [guide](expanding-lvm-thinpool.md) as required

It is assumed that gluster brick deamon is up and running, while this expansion
is in progress (IOW, this is an online expansion procedure).

1. Expand the backing LVM thin pool if required
    - See this [guide](expanding-lvm-thinpool.md)

2. Extend the thin LV backing the XFS instance
    - Check and note the thin LV size `sudo lvs <vg-name>/<vg-name>`
    - `sudo lvextend -L<size>  /dev/mapper/<vg-name>-<vg-name>`
        - <size> is the new size for the LV, not the amount by which to extend
            the LV
        - As of this writing, the LV for the active file system is typically
        sized at half of the thin pool size so that a 50% reserve is maintained
        for volume snapshots
    - Recheck LV size `lvs <vg-name>/<vg-name>` to ensure it has expanded

3. Resize the XFS filesystem
    - Check the reported size of XFS, `df -kH <xfs-mountpoint>`
    - `sudo xfs_growfs <xfs-mountpoint>`
    - Recheck XFS size, `df -kH <xfs-mountpoint>` to ensure it now reports the
        expanded size

4. Repeat steps 1-3 on all nodes that form the Gluster volume

5. Check reported size of gluster mount on any client
    - `df -kH <gluster-mountpoint>`

## Example inputs:
- `<vg-name>`        : supervol00 (can also be seen as volume name as that is
                                how the ansible plays create the LVM structure)
- `<size>`           : 750G
- `<xfs-mountpoint>` : /bricks/supervol00
