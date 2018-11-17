##############################################################################
#
#	Copyright (c) Geoworks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	CD Library
# FILE:		cdlibrary.gp
#
# AUTHOR:	Fred Crimi, 8/91
#
# DESCRIPTION:	This file contains the CD Library calls
#
# RCS STAMP:
#	$Id: cdrom.gp,v 1.1 97/04/04 17:44:00 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name cdrom.lib

# Specify geode type: is a library, will have its own process (thread),
# and is not multi-launchable.
#
type	library, single
#
# Define the library entry point
#
entry CDRomEntry
#

#
# Import definitions from the kernel
#
library geos

#
# Desktop-related things
# 
longname	"CD Rom Library"
tokenchars	"CDRM"
tokenid		0

#
# Specify alternate resource flags for anything non-standard
#

resource CommonCode		shared, code, read-only


export CDGetDriveNumbers
export CDGetDriveList
export CDGetCopyright
export CDGetAbstract
export CDGetBibliography
export CDGetVTOC
export CDGetDiskRead
export CDGetDiskWrite
export CDGetDriveCheck
export CDGetExtenVersion
export CDGetDriveLetters
export CDGetVolDescriptor
export CDGetDirectoryEntry
export CDInit
export CDInputFlush
export CDOutputFlush
export CDDeviceOpen
export CDDeviceClose
export CDReadAddressDeviceHeader
export CDHeadLocation
export CDAudioChannelInfo
export CDReadDriveBytes
export CDDeviceStatus
export CDSectorSize
export CDVolumeSize
export CDMediaChanged
export CDAudioDiskInfo
export CDAudioTrackInfo
export CDQChannelInfo
export CDSubChannelInfo
export CDUpcCode
export CDAudioStatus
export CDIOCTLInput
export CDIOCTLOutput
export CDEjectDisk
export CDLockDoor
export CDResetDrive
export CDAudioChannelControl
export CDCloseTray
export CDSeek
export CDPlayAudio
export CDStopAudio
export CDResumeAudio
export CDReadLong
export CDReadLongPrefetch
export CDWriteLong
export CDWriteLongVerify
export ConvertRedBookToAbsolute
export Int2f
















