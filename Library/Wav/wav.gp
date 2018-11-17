##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		wav.gp
#
# AUTHOR:	Steve Scholl
#
#	$Id: wav.gp,v 1.1 97/04/07 11:51:29 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name wav.lib

#
# Imported libraries
#

library geos
library sound

ifndef GPC_ONLY
# lib rary bsn wav
endif

#
# Specify geode type
#
type	library, single

#
# Desktop-related things
#
longname	"Wav Library"
tokenchars	"WAV "
tokenid		0

#
# Define the library entry point
#
# We have no entry point

#
# Define resources other than standard discardable code
#
nosort
resource WavCode	read-only code shared
resource Fixed		fixed read-only code shared

#
# Exported Classes
#

# Controllers

#
# Export routines
#

export	WavPlayFile
export	PlaySoundFromFile

incminor
export	WAVPLAYFILE
export	PLAYSOUNDFROMFILE
incminor
export  WavPlayInitSound
export  WAVPLAYINITSOUND
incminor
export	WavLockExclusive
export	WavUnlockExclusive

