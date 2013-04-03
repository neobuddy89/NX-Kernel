#!/bin/bash

###############################################################################
# To all DEV around the world :)                                              #
# to build this kernel you need to be ROOT and to have bash as script loader  #
# do this:                                                                    #
# cd /bin                                                                     #
# rm -f sh                                                                    #
# ln -s bash sh                                                               #
# now go back to kernel folder and run:                                       # #                                                         		      #
# sh clean_kernel.sh                                                          #
#                                                                             #
# Now you can build my kernel.                                                #
# using bash will make your life easy. so it's best that way.                 #
# Have fun and update me if something nice can be added to my source.         #
###############################################################################

# location
export KERNELDIR=`readlink -f .`
export PARENT_DIR=`readlink -f ..`

# kernel
export ARCH=arm
export USE_SEC_FIPS_MODE=true
export KERNEL_CONFIG="nx_defconfig"

# build script
export USER=`whoami`
export OLDMODULES=`find -name *.ko`

# system compiler
# gcc 4.7.2 (Linaro 12.07)
export CROSS_COMPILE=${KERNELDIR}/android-toolchain/bin/arm-eabi-

NAMBEROFCPUS=`grep 'processor' /proc/cpuinfo | wc -l`

if [ "${1}" != "" ]; then
	export KERNELDIR=`readlink -f ${1}`
fi;

if [ ! -f ${KERNELDIR}/.config ]; then
	echo "***** Writing Config *****"
	cp ${KERNELDIR}/arch/arm/configs/${KERNEL_CONFIG} .config
	make ${KERNEL_CONFIG}
fi;

. ${KERNELDIR}/.config

# remove previous zImage files
if [ -e ${KERNELDIR}/zImage ]; then
	rm ${KERNELDIR}/zImage
	rm ${KERNELDIR}/boot.img
fi;
if [ -e ${KERNELDIR}/arch/arm/boot/zImage ]; then
	rm ${KERNELDIR}/arch/arm/boot/zImage
fi;

# remove all old modules before compile
cd ${KERNELDIR}
for i in $OLDMODULES; do
	rm -f $i
done;

echo "***** Removing Old Compile Temp Files *****"
echo "***** Please run 'sh clean_kernel.sh' for Complete Clean *****"
# remove previous initramfs files
rm -rf /tmp/cpio* >> /dev/null
rm -rf out/system/lib/modules/* >> /dev/null
rm -rf out/temp/* >> /dev/null
rm -r out/temp >> /dev/null


# clean initramfs old compile data
rm -f usr/initramfs_data.cpio >> /dev/null
rm -f usr/initramfs_data.o >> /dev/null

cd ${KERNELDIR}/

mkdir -p out/system/lib/modules
mkdir -p out/temp

# make modules and install
echo "***** Compiling modules *****"
if [ $USER != "root" ]; then
	make -j${NAMBEROFCPUS} modules || exit 1
	make -j${NAMBEROFCPUS} INSTALL_MOD_PATH=out/temp modules_install || exit 1
else
	nice -n -15 make -j${NAMBEROFCPUS} modules || exit 1
	nice -n -15 make -j${NAMBEROFCPUS} INSTALL_MOD_PATH=out/temp modules_install || exit 1
fi;

# copy modules
echo "***** Copying modules *****"
cd out
find -name '*.ko' -exec cp -av {} "${KERNELDIR}/out/system/lib/modules" \;
${CROSS_COMPILE}strip --strip-debug "${KERNELDIR}"/out/system/lib/modules/*.ko
chmod 755 "${KERNELDIR}"/out/system/lib/modules/*
cd ..

# remove temp module files generated during compile
echo "***** Removing temp module stage 2 files *****"
rm -rf out/temp/* >> /dev/null
rm -r out/temp  >> /dev/null

# check if ramdisk available
if [ ! -e ${KERNELDIR}/ramdisk.cpio ]; then
	cd ../NX-initramfs
	./mkbootfs root > ramdisk.cpio
	cd ${KERNELDIR}
	cp ../NX-initramfs/ramdisk.cpio ${KERNELDIR}
	echo "***** Ramdisk Generated *****"
fi;

# check if recovery available
if [ ! -e ${KERNELDIR}/ramdisk-recovery.cpio ]; then
	cd ../NX-initramfs
	./mkbootfs recovery/root > ramdisk-recovery.cpio
	cd ${KERNELDIR}
	cp ../NX-initramfs/ramdisk-recovery.cpio ${KERNELDIR}
	echo "***** Recovery Generated *****"
fi;

# make zImage
echo "***** Compiling kernel *****"
if [ $USER != "root" ]; then
	time make -j${NAMBEROFCPUS} zImage
else
	time nice -n -15 make -j${NAMBEROFCPUS} zImage
fi;

echo "***** Final Touch for Kernel *****"
if [ -e ${KERNELDIR}/arch/arm/boot/zImage ]; then
	cp ${KERNELDIR}/arch/arm/boot/zImage ${KERNELDIR}/zImage
	stat ${KERNELDIR}/zImage
	./acp -fp zImage boot.img
	# copy all needed to out kernel folder
	rm ${KERNELDIR}/out/boot.img >> /dev/null
	rm ${KERNELDIR}/out/NX-Kernel_* >> /dev/null
	stat ${KERNELDIR}/boot.img
	GETVER=`grep 'NX-Kernel_v.*' arch/arm/configs/${KERNEL_CONFIG} | sed 's/.*_.//g' | sed 's/".*//g'`
	cp ${KERNELDIR}/boot.img /${KERNELDIR}/out/
	cd ${KERNELDIR}/out/
	zip -r NX-Kernel_v${GETVER}-`date +"[%m-%d]-[%H-%M]"`.zip .
	echo "***** Ready to Roar *****"
	while [ "$push_ok" != "y" ] && [ "$push_ok" != "n" ]
	do
	      read -p "Do you want to push the kernel to the sdcard of your device? (y/n)" push_ok
	done
	if [ "$push_ok" == "y" ]
		then
		STATUS=`adb get-state` >> /dev/null;
		while [ "$STATUS" != "device" ]
		do
			sleep 1
			STATUS=`adb get-state` >> /dev/null
		done
		adb push ${KERNELDIR}/out/NX-Kernel_v*.zip /sdcard/
	else
		echo "Finished!"
		exit 0;
	fi;
else
	echo "Kernel STUCK in BUILD!"
fi;
