COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2026 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File System Drivers
FILE:		hostfsManager.asm

DESCRIPTION:
	Host file system driver for pcgeos-basebox.

	A secondary file system driver that manages up to eight drives,
	each serving a host directory. Every request is forwarded to the
	emulator as a HostFsFrame (port 38FFh, host interface sub-API 5);
	the emulator resolves paths, names and GEOS file headers against
	the host directory as it is right now, and reads or writes guest
	memory directly for paths, buffers and extended attributes.

	This driver only does what has to happen inside GEOS: driver and
	drive registration, current path blocks, calling the kernel back
	during FileEnum, and file-change notifications.

	Configuration, in GEOS.INI:
		[system]
		fs = hostfs.geo

		[hostfs]
		drives = {
		HOST=C:\Users\me\GeosData
		WORK=/home/me/work
		}
	Each line becomes a drive named NAME, showing the host directory
	as it is right now. The emulator can restrict which directories
	may be mounted (BASEBOX_GEOS_HOSTFS_ALLOW).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	hostfsGeode.def
include	hostfsConstant.def
include	hostfsVariable.def

include	hostfsEntry.asm
include	hostfsCall.asm
include	hostfsInit.asm
include	hostfsDisk.asm
include	hostfsPath.asm
include	hostfsIO.asm
include	hostfsWatch.asm
