# Some sneak cheat codes

... or what I'm able to do without begging downtime windows

## Grow a kvm guest disk / fs online without rebooting

My setup is a bit wierd since I define the storage of my vms with LVM on the hypervisor. This setup allows me to define for each vm / vdevices the tier used, if it needs flash cache, and with king of raid, depending the io profile (elasticsearch vs cold nfs vs ceph lab...) 

**On the kvm hyp:**

Grow the vm disk device/image. For instance to grow the logical volume up to 150GB: 

``` 
# lvresize -L 150G /dev/pool/drive
```
This will change the size of the lv to 150GB

=> `lvdisplay /dev/pool/drive ` will show the new **LV Size**

Notify the new size via hmp on the guest:

``` 
# virsh qemu-monitor-command drive block_resize drive-virtio-disk0 150G --hmp 
```
**Now look at the bright side on the guest:**

The device growth has been reported in the kernel log of the guest - dmesg:
```
# dmesg
[...]
[937977.367836] virtio_blk virtio2: new size: 314572800 512-byte logical blocks (161 GB/150 GiB)
[937977.369322] vda: detected capacity change from 107374182400 to 161061273600
```
Now it's time to jump into the void by deleting the partition entry

Don't be scared. This will not touch data, only the entry point of the filesystem. There nothing to worry (except a power issue)

What we'll gonna do is to change the end boundary of the physical volume partition. If the PV is the whole device, this fdisk stuff can be skipped 

```
# fdisk /dev/vda
Command (m for help): p
Disk /dev/vda: 150 GB, 166429982720 bytes, 325058560 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

Device      Boot    Start         End      Blocks   Id  Type
/dev/vda1   *        2048     1026047      512000   83  Linux
/dev/vda2         1026048   208689152   103831552   8e  Linux LVM

Command (m for help): d
Partition number (1,2, default 2): 2

Partition 2 has been deleted.
Command (m for help): n
Partition type
   p   primary (1 primary, 0 extended, 3 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (2-4, default 2): 
```
**¡¡ Be carreful to double check that the "First sector" remains unchanged !!**

**... and that the Last one is beyond the previous "Last sector" :**
```
First sector (2099200-1000215215, default 2099200): 
Last sector, +sectors or +size{K,M,G,T,P} (2099200-1000215215, default 1000215215): 
```
```
Created a new partition 2 of type 'Linux' and of size 476 GiB.
Command (m for help): t
Partition number (1,2, default 2): 
Hex code (type L to list all codes): 8e

Changed type of partition 'Linux' to 'Linux LVM'.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Re-reading the partition table failed.: Device or resource busy

The kernel still uses the old table. The new table will be used at the next reboot or after you run partprobe(8) or kpartx(8).

```
Notify the kernel with the new parts table
```
# partx -u /dev/vda
```
Resize the PV by the new dev size
```
# pvresize /dev/vda2
```
Resize the fs with its underlying logical volume with all the new space of the vg
```
# lvresize -l +100%FREE /dev/mapper/vg0-root -r
```

Now issue a `df` to enjoy ;)
