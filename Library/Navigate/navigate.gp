##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Navigation Library
# MODULE:	Navigate Controller
# FILE:		navigate.gp
#
# AUTHOR:	Alvin Cham, Sep 26, 1994
# 
#	$Id: navigate.gp,v 1.1 97/04/05 01:24:43 newdeal Exp $
#
##############################################################################
#
name navigate.lib

library	geos
library	ui

#
# Specify geode type.
#
type	library, single

#
# Desktop-related things
#
longname	"Navigation Library"
tokenchars	"NAVL"
tokenid		0

#
# We want this to run on Zoomer
#
#platform zoomer

#
# Define resources other than standard discardable code.
#
#resource ContentTemplate object read-only shared
#resource BookFileSelectorTemplate ui-object read-only shared
#resource PointerImages	 lmem read-only shared
#resource ContentStrings	 lmem read-only shared

#
# Define resources for the Navigate controller.
#
resource NavigateTemplate object read-only shared
resource NavigateStrings lmem read-only shared
resource NavigateToolUI  object read-only shared
resource NavigateUI	   object read-only shared 
resource NavigateTCMonikerResource lmem read-only shared
resource NavigateTMMonikerResource lmem read-only shared

#
# Define resources for the find controller. (search)
#
#resource ContentFindStrings read-only shared lmem
#resource ContentFindToolUI  read-only shared object
#resource ContentFindUI	    read-only shared object
#resource ContentFindSearchControlTemplate    read-only shared object
#resource ContentFindControlCode read-only code shared
#resource ContentFindTCMonikeResource lmem read-only shared
#resource ContentFindTMMonikeResource lmem read-only shared

#
# Define resources for the send controller.
#
#resource ContentSendStrings read-only shared lmem
#resource ContentSendToolUI  read-only shared object
#resource ContentSendUI	    read-only shared object
#resource ContentSendTemplate    read-only shared object
#resource ContentSendControlCode read-only code shared
#resource ContentSendTCMonikeResource lmem read-only shared
#resource ContentSendTMMonikeResource lmem read-only shared


#
# Define resources for the context controller (status bar).
#
#resource ContextStrings     lmem read-only shared
#resource ContextToolUI	    object read-only shared

#
# Export routines.
#
#export ContentGenViewClass
#export ContentDocClass
#export ContentTextClass
#export ContentNavControlClass
#export ContentFindControlClass
#export ContentSendControlClass
#export ContextControlClass
export NavigateControlClass
