# MBR: Master Boot Record

## Backup MBR and partitions

```bash
root@server: sfdisk -l /dev/hda > MonFichier.part #Partitions
root@server: dd if=/dev/hda of=<path>/mbr.img bs=512 count=1 #MBR
```

## Restore MBR and partitions

```bash
root@server: /dev/hda < MonFichier.part #Partitions
root@server: dd if=<path>/mbr.img of=/dev/hda bs=512 count=1 #MBR
```
