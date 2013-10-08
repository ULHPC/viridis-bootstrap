Viridis environment generation
==============================

# Generate the environment

Edit the configuration variables in bootstrap.sh and execute it:

    ./bootstrap.sh
    
    [...]
    
    == OUTPUT ==
    Image : /tmp/wheezy-ref.img
    Initrd: /tmp/wheezy-initrd
    Kernel: /tmp/wheezy-kernel'

# Generate the initrd

Execute mkinitrd.sh, the parameter is the **absolute path** to the original initrd

    ./mkinitrd.sh /tmp/wheezy-initrd

# Push in production

Move the files in /srv/iscsi & /srv/tftp on boot.viridis

