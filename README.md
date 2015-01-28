# WindowsVFIO
Configuration files and instructions for setting up a Windows VM with a VFIO GPU

The script and configuration files here are designed for Arch Linux with a
Windows 7 VM being managed with libvirt. Feel free to try this with other
setups, but please do not report bugs unless you feel it is relevant to this
setup. For more detail, feel free to read the discussion in the following
thread:

https://bbs.archlinux.org/viewtopic.php?id=162768

## Dependencies

* [qemu](https://www.archlinux.org/packages/extra/x86_64/qemu/)
* [libvirt](https://www.archlinux.org/packages/community/x86_64/libvirt/)
* A linux kernel at least at version 3.14 with the option
  `CONFIG_VFIO_PCI_VGA=y`

If your graphics card that you are passing is not in it's own iommu group, then
you may need to use [a patch to override
acs](https://lkml.org/lkml/2013/5/30/513).

If you are using the i915 drivers on your host, you may need to use [a patch to
fix the VGA arbiter](https://lkml.org/lkml/2014/5/9/517).

A packaged mainline kernel with both patches applied can be found in forum's
thread.

## Instructions

You may either run the setup.sh script to automatically install and set up the
required configuration, or manually follow the directions below. If you use the
script, follow the directions in Creating a VM below.

### Setting up user permissions
*Note that this may not be necessary if trying to connect to libvirt as root*

*If you'd prefer file-permissions instead of polkit, refer to the [following
section of the Arch Wiki's libvirt
page.](https://wiki.archlinux.org/index.php/Libvirt#Authenticate_with_file-based_permissions)*


1. Create the `libvirt` group and add your user(s) to it.
2. As root, create the file
   `/etc/polkit-1/rules.d/50-org.libvirt.unix.manage.rules` with the following:

    ````
    polkit.addRule(function(action, subject) {
        if (action.id == "org.libvirt.unix.manage" &&
            subject.isInGroup("libvirt")) {
            return polkit.Result.YES;
        }
    });
    ````

### Setting up QEMU permissions
1. Create the `kvm` group.
2. Open up `/etc/libvirt/qemu.conf` and append `user=root` and `group=kvm` to
   the file.
3. Append the line `cgroup_device_acl = [ "/dev/vfio/<IOMMU_GROUP>" ]` to the
   file as well, replacing `<IOMMU_GROUP>` with the iommu group that your
   graphics card is in.

### The kernel parameters
1. Add `intel_iommu=on` to your kernel's parameters
2. Get your card's ID with `lspci -n` (it will be in hex form of ####:####) and
   add `pci-stub.ids=<DEVICE ID>` to your kernel parameters, replacing `<DEVICE
   ID>` with your card's ID.
3. If you're using the ACS override patch, add `pcie_acs_override=downstream` to
   your kernel parameters.
4. If you're using i915 drivers on your host, add `i915.enable_hd_vgaarb=1` to
   your kernel parameters.

### Kernel modules
1. Add `pci-stub` to the `MODULES` section in `/etc/mkinitcpio.conf`
2. Blacklist the driver of the card you are passing (either nouveau for Nvidia
   or radeon for AMD/ATI)
3. Run `mkinitcpio` to generate the proper startup configuration for your
   system.

### Creating the VM
1. Create your Windows VM using whatever method you prefer. Make sure that you
   are not using the virtual q35 chipset.
2. Open the VM's configuration and modify the following:

* At the beginning, replace the line:

    `<domain type='kvm'>`

    with:

    `<domain type='kvm'
    xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>`

* Right after `</devices>`, add the following lines:

    ```
    <qemu:arg value='-vga'/>
    <qemu:arg value='none'/>
    <qemu:arg value='-device'/>
    <qemu:arg value='vfio-pci,host=<DEVICE NUMBER>,x-vga=on'/>
    ```

Replace `<DEVICE NUMBER>` with your device's.

Your VM should now be all set to use a VFIO VGA passthrough!
