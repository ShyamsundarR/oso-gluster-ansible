# Expanding LVM thin pool backing the gluster brick

This document details the operational procedure to expand a LVM thin pool that
is used to back the Gluster bricks, created using the ansible plays in this
repository.

The LVM thin pool may need expansion due to a few reasons, such as,
    - Increasing the available space in the thin pool to accommodate snapshot
    space growth
    - Increasing the XFS filesystem size to address space limitations in the
    active volume

This document stops at expanding the LVM thin pool, if further expansion of the
filesystem is required, follow this [guide](resizing-gluster-brick.md).

It is assumed that gluster brick deamon is up and running, while this expansion
is in progress (IOW, this is an online expansion procedure).

1. Expand the EBS instance
    - There are no specific instructions here, AWS website links are the source
    of truth [1]

2. Pre-flight checks before expanding the backing PV for the EBS disk
    - Check size of disk: `sudo fdisk -l <dev-path-to-disk>`
    - Check pv size of containing disk: `sudo pvs <dev-path-to-disk>`
    - If sizes differ, and PV size is smaller than the disk size, proceed!
    - Note the existing VG size `sudo vgs <vg-name>`

3. Resize the PV
    - `sudo pvresize <dev-path-to-disk>`
    - Check new PV size, `sudo pvs <dev-path-to-disk>` and cross check with
        earlier reported disk size
    - Check the new VG size, `sudo vgs <vg-name>` and cross check with PV size

4. Extend the thin-pool
    - Check the current thin pool size `sudo lvs <vg-name>/pool`
    - If LV size is smaller than the new VG size, proceed
    - `sudo lvextend -l 100%VG /dev/mapper/<vg-name>-pool`
        - Extend the thin pool to occupy entire VG as there is a single
    thin pool on a given VG in the prescribed setup
    - Recheck LV size `lvs <vg-name>/pool` to ensure it has expanded

5. Repeat steps 1-4 on all nodes that form the Gluster volume

## Example inputs:
- `<dev-path-to-disk>`: /dev/xvdb
- `<vg-name>`         : supervol00 (can also be seen as volume name as that is
                                how the ansible plays create the LVM structure)

## links
[1] AWS "Modifying the Size, IOPS, or Type of an EBS Volume on Linux" :
    https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-modify-volume.html
