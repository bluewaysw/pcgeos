##############################################################################
#
#	(c) Copyright Geoworks 1995 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	PC GEOS
# MODULE:	Start up application
# FILE:		rstartup.gp
#
# AUTHOR:	Jason Ho, Apr 14, 1995
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#	kho	4/14/95		Initial version.
#
# 
#
#	$Id: rstartup.gp,v 1.1 97/04/04 16:52:38 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name rstart.app
#
# Long filename
#
longname "Start up"
#
# Token information
#
tokenchars "STAU"		# if you change this, change
				# rstartupProcess.asm before VpCloseIacp
tokenid 0
#
# Specify geode type
#
type	appl, process, single, discardable-dgroup
#
# Specify stack size
#
# stack	2000
#
# Specify heap size
#
heapspace 50k
#
# Specify class name for process
#
class	RStartupProcessClass
#
# Specify application object
#
appobj	RStartupApp
#
# Import library routine definitions
#
library	geos
library	ui
library text
library rwtime
#
# Define resources other than standard discardable code
#
resource AppResource			object
resource Interface			object
# resource RStartupFlashNote		object
resource CommonCode			code read-only shared 
resource RStartupClassStructures	fixed read-only shared
resource StringsResource		lmem shared read-only

export RStartupProcessClass
export RStartupApplicationClass
export RStartupCountryListClass

ifdef GP_RSTARTUP_DO_LANGUAGE
export RStartupLangDynamicListClass
endif
export RStartupContactEditClass
