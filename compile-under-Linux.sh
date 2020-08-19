#!/bin/bash
BUILD_DIR="$(pwd)"


# Get OpenWatcom
if [ ! -d _watcom ]
then
	wget https://github.com/open-watcom/open-watcom-v2/releases/download/Current-build/ow-snapshot.tar.gz
	gzip -d ow-snapshot.tar.gz
	mkdir _watcom
	mkdir _out
	cd _watcom
	tar -xf ../ow-snapshot.tar
	cd ..
fi



# Compile FreeGEOS
export PATH=$PATH:$BUILD_DIR/_watcom/binl64:$BUILD_DIR/bin
export WATCOM=$BUILD_DIR/_watcom
export ROOT_DIR=$BUILD_DIR
export LOCAL_ROOT=$BUILD_DIR/_out
cd $BUILD_DIR/Tools/pmake/pmake
wmake install
cd $BUILD_DIR/Installed/Tools
pmake install
cd $BUILD_DIR/Installed
pmake | tee $BUILD_DIR/_build.log | grep -i -v "esp \|goc \|wcc \|wcc32 \|warning\|watcom"
cd $BUILD_DIR/Tools/build/product/bbxensem/Scripts
echo pc >$BUILD_DIR/_temp.dat
echo y >>$BUILD_DIR/_temp.dat
echo n >>$BUILD_DIR/_temp.dat
echo y >>$BUILD_DIR/_temp.dat
echo n >>$BUILD_DIR/_temp.dat
echo $BUILD_DIR/_out >> $BUILD_DIR/_temp.dat
perl -I. buildbbx.pl  <$BUILD_DIR/_temp.dat



# Move ensamble directory with the compiled "distribution" into current directory
cd "$BUILD_DIR"
mv _out/localpc/ensemble .



# Patch geosec.ini to make FreeGEOS use the os2ec.geo filesystem driver that works under DOSBox
sed -i 's/fs = .*geo/primaryfsd = os2ec.geo/' ensemble/geosec.ini



# Search for the PC/GEOS serial number in the repository
serial="$(find | egrep geos.*\.ini | xargs -n1 grep serialNumber | uniq | sort | tail -1)"

# Patch geosec.ini to make the setup not ask for a serial
if [ $(grep -c serialNumber ensemble/geosec.ini) -eq 0 ]
then
	sed -i "/\[system\]/a $serial" ensemble/geosec.ini
fi