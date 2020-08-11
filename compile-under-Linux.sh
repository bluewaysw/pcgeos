#!/bin/bash
BUILD_DIR="$(pwd)"

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
