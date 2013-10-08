Viridis environment generation
==============================

# Generate the environment

Edit the configuration variables in `bootstrap.sh` and execute it:

    ./bootstrap.sh
    
    [...]
    
    == OUTPUT ==
    Image : /tmp/wheezy-ref.img
    Initrd: /tmp/wheezy-initrd
    Kernel: /tmp/wheezy-kernel'

If you want to resize the image:

    e2fsck -f wheezy-ref.img
    resize2fs wheezy-ref.img 2G

`resize2fs` will resize the image file and ext4 filesystem to 2GB.

# Generate the initrd

Execute `mkinitrd.sh`, the parameter is the **absolute path** to the original initrd

    ./mkinitrd.sh /tmp/wheezy-initrd
    
    [...]
    
    === OUTPUT ===
    Initrd custom: /tmp/wheezy-initrd-customized

# Push in production

Move the files in /srv/iscsi & /srv/tftp on `boot.viridis`

