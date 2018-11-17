##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	Geode Parameters
# FILE:		saver.gp
#
# AUTHOR:	Adam de Boor, Dec  8, 1992
#
#
# 
#
#	$Id: saver.gp,v 1.1 97/04/07 10:44:20 newdeal Exp $
#
##############################################################################
#
name saver.lib

type library, single

longname "Lights Out"
tokenchars "LOUT"
tokenid 0

#
# Import library routine definitions
#
library	geos
library	ui
library net  noload

nosort
resource SaverFixedCode shared code fixed read-only
resource SaverAppCode	code read-only shared
resource SaverCryptCode	code read-only shared
resource SaverFadeCode	code read-only shared
resource SaverOptionCode	code read-only shared
resource SaverRandomTemplate	code read-only shared
resource SaverRandomCode	code read-only shared
resource SaverUtilsCode	code read-only shared
resource SaverVectorCode	code read-only shared
resource Interface	shared ui-object
resource SaverStrings	shared lmem read-only

#
# Heap space guess (2400 bytes/16)
#
heapspace 150

#
# Password encryption
#
export	SaverCryptInit
export	SaverCryptEncrypt
export 	SaverCryptDecrypt
export 	SaverCryptEnd

#
# Random numbers
#
export	SaverSeedRandom
export	SaverRandom
export	SaverEndRandom

#
# Motion vectors
#
export	SaverVectorInit
export	SaverVectorUpdate

#
# Background bitmap stuff
#
export	SaverDrawBGBitmap

#
# Fades & wipes
#
export SaverFadePatternFade
export SaverFadeWipe

#
# Misc
#
export SaverCreateLaunchBlock
export SaverDuplicateALB
export SaverApplicationGetOptions

#
# C stubs
#
export SAVERCREATELAUNCHBLOCK
export SAVERDUPLICATEALB
export SAVERSEEDRANDOM
export SAVERRANDOM
export SAVERENDRANDOM
export SAVERCRYPTINIT
export SAVERCRYPTENCRYPT
export SAVERCRYPTDECRYPT
export SAVERCRYPTEND
export SAVERVECTORINIT
export SAVERVECTORUPDATE
export SAVERFADEPATTERNFADE
export SAVERFADEWIPE
export SAVERDRAWBGBITMAP
export SAVERAPPLICATIONGETOPTIONS

#
# Classes
#
export	SaverApplicationClass
export	SaverContentClass	# internal use
