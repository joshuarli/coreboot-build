# coreboot-build

coreboot build environment. supports at least (as far as I have tested):

- coreboot cross toolchain for i386 (git checkout at time of build)
    - precompiled if you pull the image from docker hub!
- coreboot build for
    - x200
    - x201 tablet
    - x220
- seaBIOS
- ifdtool
- me_cleaner


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
