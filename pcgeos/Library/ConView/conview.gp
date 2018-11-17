##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	ConView Library
# FILE:		conview.gp
#
# AUTHOR:	Jonathan Magasin, Apr  8, 1994
#
#
# 
#
#	$Id: conview.gp,v 1.1 97/04/04 17:49:54 newdeal Exp $
#
##############################################################################
#
name conview.lib

library	geos
library	ui
library spool			# for PrintControl
library	compress noload

#
# Specify geode type.
#
type	library, single

#
# Desktop-related things
#
longname	"Book Reader Library"
tokenchars	"BKRL"
tokenid		0

#
# We want this to run on Zoomer
#
ifdef PRODUCT_ZOOMER
platform zoomer
endif

nosort
resource ConviewClassStructures	shared, fixed, read-only
ifdef GP_FULL_EXECUTE_IN_PLACE
resource ConviewControlInfoXIP	shared, read-only
endif

#
# Define resources other than standard discardable code.
#
resource ContentTemplate 		read-only shared object
resource BookFileSelectorTemplate 	read-only shared ui-object
resource PointerImages	 		read-only shared lmem
resource ContentStrings	 		read-only shared lmem
ifdef GP_JEDI
resource BookDeleteUI 			read-only shared ui-object
endif

#
# Define resources for the navigation controller.
#
resource ContentNavTemplate 		read-only shared ui-object
resource ContentNavStrings 		read-only shared lmem
resource ContentNavToolUI  		read-only shared ui-object
resource ContentNavUI	   		read-only shared ui-object
#ifndef GP_NO_COLOR_MONIKERS
resource ContentNavTCMonikerResource 	read-only shared lmem
#endif
#resource ContentNavTMMonikerResource 	read-only shared lmem

#
# Define resources for the find controller. (search)
#
resource ContentFindStrings 		lmem read-only shared
resource ContentFindToolUI  		ui-object read-only shared
resource ContentFindUI	    		ui-object read-only shared
resource ContentFindSearchControlTemplate    ui-object read-only shared
resource ContentFindControlCode 	code read-only shared
#ifndef GP_NO_COLOR_MONIKERS
resource ContentFindTCMonikeResource 	lmem read-only shared
#endif
#resource ContentFindTMMonikeResource 	lmem read-only shared

#
# Define resources for the send controller.
#
resource ContentSendStrings 		lmem read-only shared
resource ContentSendToolUI  		ui-object read-only shared
resource ContentSendUI	    		ui-object read-only shared
ifndef GP_JEDI
resource ContentSendTemplate    	ui-object read-only shared
endif
resource ContentPrintTemplate    	ui-object read-only shared
resource ContentSendControlCode 	code read-only shared
#ifndef GP_NO_COLOR_MONIKERS
resource ContentSendTCMonikeResource 	lmem read-only shared
#endif
#resource ContentSendTMMonikeResource 	lmem read-only shared


#
# Define resources for the context controller (status bar).
#
resource ContextStrings     		lmem read-only shared
resource ContextToolUI	    		ui-object read-only shared

#
# Export routines.
#
export ContentGenViewClass
export ContentDocClass
export ContentTextClass
export ContentNavControlClass
export ContentFindControlClass
export ContentSendControlClass
export ContextControlClass
ifdef GP_JEDI
export ContentFileSelectorClass 
endif

incminor ProtoNewForJedi
