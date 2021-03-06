# coreboot-build

coreboot build environment based on debian-unstable via docker. contains:

- coreboot cross toolchain for i386 (git checkout at time of build)
- seaBIOS (git checkout at time of build)
- ifdtool (in coreboot tree)
- me_cleaner (in coreboot tree, pypy because i can)

this isn't pinned to any coreboot git sha or debian version, on purpose - to potentially catch bugs.

the latest docker image was built early may 2019. you can build the dockerfile yourself, if you want more recent stuff, but be aware compiling coreboot's cross toolchain takes a long time (a motivation).

successfully builds coreboot roms for at least (as far as I have tested):

- x201 tablet (at least may 2019 docker image)
- x220 (at least may 2019 docker image)
- x230 (at least may 2019 docker image)


## x200

i've corebooted x200 successfully, but the process is quite a bit different compared to x201t/x220, and my notes are partially lost to time, so TODO.


## x201 tablet

connect spi programmer and read original spi flash, for example:

    $ flashrom -p ch341a_spi -c MX25L6436E/MX25L6445E/MX25L6465E/MX25L6473E -r original.bin
    $ flashrom -p ch341a_spi -c MX25L6436E/MX25L6445E/MX25L6465E/MX25L6473E -r compare.bin
    $ cmp original.bin compare.bin  # also view as hex to make sure looks legit as opposed to all 0x00 / 0xff

add to dir soon-to-be volume mounted:

    $ mkdir out
    $ mv original.bin out

shell into the image:

    $ docker run --rm -it -v "${PWD}/out":/out joshuarli/coreboot-build:latest

extract regions to expected places, neutralize intel me:

    (inside) $ ifdtool -x /out/original.rom
    (inside) $ cp flashregion_0_flashdescriptor.bin 3rdparty/blobs/mainboard/lenovo/x201/descriptor.bin
    (inside) $ me_cleaner -O 3rdparty/blobs/mainboard/lenovo/x201/me.bin flashregion_2_intel_me.bin
    (inside) $ cp flashregion_3_gbe.bin 3rdparty/blobs/mainboard/lenovo/x201/gbe.bin

build coreboot rom (add bins back in chipset menu):

    (inside) $ make menuconfig
    (inside) $ make
    (inside) $ mv build/coreboot.rom /out
    ^D

flash coreboot, for example:

    $ flashrom -p ch341a_spi -c MX25L6436E/MX25L6445E/MX25L6465E/MX25L6473E -w out/coreboot.rom


## x220

same general procedure as x201 tablet


## x230

connect spi programmer and read original flash from both chips, for example:

    $ flashrom -p ch341a_spi -c MX25L3206E/MX25L3208E -r upper-original-bios.bin    
    $ flashrom -p ch341a_spi -c MX25L6406E/MX25L6408E -r lower-intel-me.bin

remember to read more than once and integrity check.

similar procedure for shelling into the image and building coreboot. when you check the x230 mainboard menuconfig option, 12 MB size will be autofilled. leave it; a stub intel firmware descriptor will be built, which you need to discard post-build and create the 4 MB coreboot image:

    (inside) $ dd if=build/coreboot.rom of=/out/coreboot.rom bs=1M skip=8

neutralize intel me:

    (inside) $ me_cleaner -S -O /out/lower-intel-me-neutralized.bin /out/lower-intel-me.bin
    ^D

flash coreboot and the neutralized intel me to their respective chips.
