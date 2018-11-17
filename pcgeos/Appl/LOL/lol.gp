##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	Geode Parameters
# FILE:		lol.gp
#
# AUTHOR:	Adam de Boor, Dec 10, 1992
#
#
# 
#
#	$Id: lol.gp,v 1.1 97/04/04 16:13:40 newdeal Exp $
#
##############################################################################
#
name lol.hack
type appl, process, single

#
# Heapspace.   I've just set to this to an arbitrary small value, as it doesn't
# really matter for lol, as it's generally the first thing run (what does 
# matter is that the huge default value isn't left in.)  -chris 1/26/94
#
heapspace 50

#
# This name is also encoded in the Preflo module (preflo.asm)
#
ifdef DO_DBCS
    longname "Lights Out App"
else
    longname "Lights Out Launcher"
endif
tokenchars	"LOL "
tokenid		0
class	LOLProcessClass
appobj	LOLApp
library geos
library ui
library saver
