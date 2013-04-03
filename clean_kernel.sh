make ARCH=arm CROSS_COMPILE=android-toolchain/bin/arm-eabi- mrproper;
make clean;
rm -f zImage;
rm -f out/zImage;
rm -f out/boot.img;
rm -f boot.img;
rm -f out/system/lib/modules/*;
rm -f out/NX-Kernel_*;

JUNK=`find . -name *.rej`;
for i in $JUNK; do
	ls $i;
	rm -f $i
done;

JUNK=`find . -name *.orig`;
for i in $JUNK; do
	ls $i;
	rm -f $i;
done;

JUNK=`find . -name *.bkp`;
for i in $JUNK; do
	ls $i;
	rm -f $i;
done;

JUNK=`find . -name *.ko`;
for i in $JUNK; do
	ls $i;
	rm -f $i;
done;

JUNK=`find . -name *.org`;
for i in $JUNK; do
        ls $i;
        rm -f $i;
done;
