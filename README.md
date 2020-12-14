# **Cyber-Homelab Vol.1**

<p align="center">
  <img src="/img/gobbleotron.gif" alt="octocat" width="300" height="250"/>
  <img src="/img/linux-kvm.png" alt="lkvm" width="400" height="200"/>
</p>

<br><br>
## Architecture 

![arch](/img/arch.png)
<br><br>

## Overview

If you want a create a homelab without spent much money, using your actual linux machine. This project might interest you. Initially, I needed to setup my computer as a developing and cybersecurity machine, so I decided to explore build my lab on VMs.
Some of the tools used on the project were:

- **Linux**.
- **KVM**.
- **QEMU**.
- **virt-manager**.
- **libvirt**.
- **virsh**.
- **Cockpit**.

<br><br>
# Hypervisor Stack

## KVM:

- Kernel-based Virtual Machine (KVM) is an open source virtualization technology built into Linux. Specifically, KVM lets you turn Linux into a hypervisor that allows a host machine to run multiple, isolated virtual environments called guests or virtual machines (VMs). *`[1]`*

<br>

## QEMU:

- QEMU (Quick EMUlator) is a free and open-source emulator and virtualizer that can perform hardware virtualization.

- QEMU is a hosted virtual machine monitor: it emulates the machine's processor through dynamic binary translation and provides a set of different hardware and device models for the machine, enabling it to run a variety of guest operating systems. It also can be used with Kernel-based Virtual Machine (KVM) to run virtual machines at near-native speed (by taking advantage of hardware extensions such as Intel VT-x). QEMU can also do emulation for user-level processes, allowing applications compiled for one architecture to run on another. *`[2]`*

<br>

## Libvirt:

- Libvirt is collection of software that provides a convenient way to manage virtual machines and other virtualization functionality, such as storage and network interface management. These software pieces include an API library, a daemon (libvirtd).

- An primary goal of libvirt is to provide a single way to manage multiple different virtualization providers/hypervisors. For example, the command 'virsh list --all' can be used to list the existing virtual machines for any supported hypervisor (KVM, Xen, VMWare ESX, etc.) No need to learn the hypervisor specific tools! *`[3]`*

<br><br>

![diagram](/img/kvm-stack.png) *`[4]`*





> **Note**: The lab setup requires many components such as a hypervisor KVM (Integrated in Linux), QEMU which emulate harware resources, interaction API like libvirt, and other many more could be installed. This solution might be a bit overwhelming and rough to setup. But belive me, it's worthy, since it can be granularly configurated.

<br><br>

## TOOLS

| User Interaction Tools                                   | Summary       | Type       |
|--------------------------------------------|--------------------------|--------------------------|
| **virsh**                         | - The virsh program is the main interface for managing virsh guest domains. <br> - The program can be used to create, pause, and shutdown domains. | **CLI** |
| **virt-manager**                 | - The virt-manager application is a desktop user interface for managing virtual machines through libvirt. <br> - It primarily targets KVM VMs, but also manages Xen and LXC (linux containers).  | **GUI** |
| **virt-install**                 | - virt-install is a command line tool for creating new KVM , Xen, or Linux container guests using the "libvirt" hypervisor management library. | **CLI** |
| **remote-viewer**                 | - The remote-viewer is a simple remote desktop display client that supports SPICE and VNC. <br> - It shares most of the features and limitations with virt-viewer. | **CLI/GUI** |
| **bridge-utils**                 | - The bridge-utils package contains a utility needed to create and manage bridge devices. <br> - This is useful in setting up networks for a hosted virtual machine (VM). | **LIB** |
| **Cockpit**                 |  - Cockpit is a server administration tool sponsored by Red Hat, focused on providing a modern-looking and user-friendly interface to manage and administer servers. | **GUI/WEB** |

<br><br>

## NETWORKING

![arch2](/img/arch2.png)

In the context of setting up a virtual machine, e1000 emulates an Intel NIC, rtl8139 emulates a Realtek NIC, and virtio is a para-virtualized driver, i.e. it "knows" it's operating in a VM and basically just passes the network traffic between the VM and the host in the most straightforward way possible.

If you are running a legacy operating system within the VM, you may need to choose the virtual NIC according to what NICs are supported in the legacy OS. Intel e1000 has drivers available for even pretty old & obscure OSs. But the hardware of the physical e1000 NIC is pretty complex, so there will be some overhead because of the need to emulate it.

Realtek 8139 apparently is pretty simple, hardware-wise, so it may be comparatively easier to emulate in a VM than Intel e1000. But on the other hand, the simplicity also means the operating system inside the VM may need to do some extra work to satisfy the conditions of the NIC emulation when the actual host NIC could do some of it in hardware.

But if whatever you're running inside the VM supports virtio, it is likely to give you the best performance (aside from host NIC hardware designed for VFIO passthrough/SR-IOV), since it allows the VM to simply skip most of the steps related to emulating the virtual NIC and controlling the virtual hardware, and the host to utilize the hardware features of the actual physical NIC for maximum benefit to the VMs' traffic.


> lspci | grep -i 'ether\|net'

| Device Model                                 | Function       | Notes       |
|--------------------------------------------|--------------------------|--------------------------|
| **virtio**                         | is a para-virtualized driver | check Disable hardware checksum offload under System > Advanced on the Networking tab and to manually reboot pfSense after saving the setting |
| **e1000e**                 | emulates an Intel NIC   | Internet works but collisions occur (Affecting network performance) |
| **rtl8139**                 | emulates a Realtek NIC | Internet works but collisions occur (Affecting network performance) |

<br>

## VirtIO Driver Support

The FreeBSD kernel used by pfSense® software includes VirtIO drivers built into the kernel. No special action is necessary to enable the drivers.
Disable Hardware Checksum Offloading

With the current state of VirtIO network drivers in FreeBSD, it is necessary to check Disable hardware checksum offload under System > Advanced on the Networking tab and to manually reboot pfSense after saving the setting, even though there is no prompt instructing to do so to be able to reach systems (at least other VM guests, possibly others) protected by pfSense software directly from the VM host.

The issue is most likely caused by FreeBSD Bug 165059.

Hardware checksums and other NIC offloading features like TSO may also need to be disabled on the hypervisor system in addition to the pfSense VM.

## Verification

> ifconfig -a 
collisions #
> arp -a
> route
> dmesg | egrep duplex
> ethtool
> mii-tool
> netstat -i

<br><br>
## Configuration

| Parameter                                | Net1 | Net2 | Net3 | Net4 | Net5 | Net6 | Net7 | Net8       | Notes       |
|-|-|-|-|-|-|-|-|-|-|
| **Name** | SysAdmin | Work | Vault | Development | Disposable | Tor | Operations | CyberSec       |  -  |
| **Networking** | No_Internet | Basic_Internet | No_Internet | Basic_Internet | Restricted_Internet | Restricted_Internet | Basic_Internet | Restricted_Internet       | Add_Notes       |
| **FileSystem**     | SSHFS | SSHFS | SSHFS | SSHFS | - | - | - | -       | Add_Notes       |
| **CPU**    | 1 | 2 | 1 | 4 | 1 | 1 | 1 | 1       | Add_Notes       |
| **RAM**    | 2048MiB | 2048MiB | 2048MiB | 8192MiB | 2048MiB | 2048MiB | 2048MiB | 8192MiB       | Add_Notes       |
| **ROM**    | 20GiB | 20GiB | 20GiB | 80GiB | - | 20GiB | 20GiB | 20GiB       | Add_Notes       |
| **Clipboard**    | N | Y | Y | Y | N | N | N | N       | Add_Notes       |
| **Addons**    | N | Y | N | Y | N | N | Y | Y       | Add_Notes       |
| **Sound**    | N | Y | N | Y | N | N | Y | Y       | Add_Notes       |
| **Display**    | virtio | QXL | virtio | QXL | virtio | virtio | virtio | virtio | Add_Notes |
| **DisAutoP**    |  | N |  | N |  |  |  |  | Add_Notes |
| **DisPort**    |  | 5900 |  | 5900 |  |  |  |  | Add_Notes |
| **DisHeads**    |  | 3 |  | 3 |  |  |  |  | Add_Notes |
| **DisRAM**    | 65536 | 131072 | 65536 | 131072 | 65536 | 65536 | 65536 | 65536 | Add_Notes |
| **DisVRAM**    | 65536 | 65536 | 65536 | 65536 | 65536 | 65536 | 65536 | 65536 | Add_Notes |
| **DisVGAmem**    | 16384 | 65536 | 16384 | 65536 | 16384 | 16384 | 16384 | 16384 | Add_Notes |
| **Parameter**    | Net1 | Net2 | Net3 | Net4 | Net5 | Net6 | Net7 | Net8       | Add_Notes       |

<br><br>
# Multiple Monitors


## Guest requirements

Both Windows and Linux guests should be configured with a QXL video device and a spice vdagent to take full advantage of the multiple monitor functionality.

## Guest QXL Configuration

One major difference between Linux and Windows QXL devices is that the Linux QXL driver supports multiple displays (up to 4) with a single video device, whereas the Windows QXL driver only supports a single display for each video device. So to enable 4 monitors, a Linux guest would need only a single QXL device, while a Windows guest would need to be configured with 4 separate QXL devices.

Since qemu 2.4.0, it is possible to limit the number of displays that a single linux driver supports by setting the qxl-vga.max_outputs. If you are using libvirt to configure your guest, you may need to ensure that the heads parameter for the video device is set properly.

## QXL Driver Video Memory

If you want to use multiple displays on your guest, you need to make sure that the device has enough video memory to support the number and size of screens you intend to use. There are several QXL parameters in qemu that you can use to control the amount of memory allocated to the QXL devices. These parameters are:

    - ram_size / ram_size_mb
    - vram_size / vram_size_mb
    - vram64_size_mb
    - vgamem_mb


<br><br>
## Screenshot

![screenshot0](/img/screenshot0.png) 
![screenshot1](/img/screenshot1.png) 
![screenshot2](/img/screenshot2.png) 

<br><br>
## References

[1] <https://www.redhat.com/en/topics/virtualization/what-is-KVM>

[2] <https://en.wikipedia.org/wiki/Qemu>

[3] <https://wiki.libvirt.org/page/FAQ#What_is_libvirt.3F>

[4] <https://octetz.com/docs/2020/2020-05-06-linux-hypervisor-setup/>

<br><br>
## License

> Licensed under the [MIT](license) license.
