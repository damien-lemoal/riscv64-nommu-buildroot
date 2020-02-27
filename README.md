Buildroot for RISC-V 64 NOMMU on Kendryte K210
==============================================

To build the toolchain and board image, run:

```
$ make riscv64_k210_defconfig
$ make
```

Buildroot will compile the complete tree including the Linux Kernel and the
busybox initramfs.

The image (`loader.bin`) will be on `output/images`. Load it into your K210 board with:

`./riscv64-uclibc-nommu/kflash.py -B goE -b 2000000 -t output/images/loader.bin`

More info on KFlash in <https://github.com/kendryte/kflash.py>. Might require some changes for other boards.

Tested boards:
- Sipeed Maix Go Suit
- Sipeed MaixDuino

For conveniance, a precompiled toolchain, the initramfs cpio
image and a Kernel (loader) file are present in the `riscv64-uclibc-nommu` directory.

## Convenience commands

### Make changes to Linux Kernel, Busybox and Buildroot

```bash
# Change Linux Kernel
make linux-menuconfig

# Change buildroot parameters
make menuconfig

# Change Busybox features
make busybox-menuconfig

# To save your changes to the repo files, use:
make busybox-update-config
make linux-update-defconfig
make savedefconfig
```

After this, run `make` or rebuild all from scratch (below).

### Rebuild all from scratch (except toolchain)

```bash
rm -rf output/images output/target
mkdir -p output/images
touch output/images/rootfs.cpio
T=(`make show-targets`)
for X in $T; do
    if [[ $X != host* ]] && [[ $X != toolchain* ]] && [[ $X != uclibc* ]]; then
        make $X-rebuild
    fi
done
make
```

## WiFi Network thru ESP8285 (WIP)

This is still a work in progress and usually the kernel complains of no memory.
The repo already includes all Kernel patches for this.

To test this, enable the following features on Linux Kernel:

```
CONFIG_NET=y
CONFIG_INET=y
CONFIG_TUN=y
```

More details on <https://github.com/laanwj/k210-sdk-stuff/tree/master/linux>.

```bash
# On K210
# The IP address is the host used as tunnel

/root/esptun tun0 /dev/ttyS1 "SSID" "Password" 192.168.15.15 23232
# Note the IP printed above to be used on your host
/sbin/ip link set dev tun0 mtu 1472
/sbin/ip addr add 10.0.1.2/24 dev tun0
/sbin/ip link set tun0 up
/sbin/ip route add default via 10.0.1.1 dev tun0

# On host
#
# The first socat IP is the K210 IP got from DHCP
# The second IP is your host IP
sudo iptables -t nat -F
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo socat UDP:192.168.15.124:23232,bind=192.168.15.15:23232 TUN:10.0.1.1/24,tun-name=tundudp,iff-no-pi,tun-type=tun,su=$USER,iff-up &
sudo ip link set dev tundudp mtu 1472
```
