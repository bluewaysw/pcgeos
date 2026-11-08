# Host file system driver for pcgeos-basebox (live, read-write).
#
# Every file system request is forwarded to the emulator, which serves a
# host directory (see src/geos/hostfs_volume.cpp in pcgeos-basebox).
#
PROTOCONST	= FS
GEODE		= hostfs

#include <$(SYSMAKEFILE)>
