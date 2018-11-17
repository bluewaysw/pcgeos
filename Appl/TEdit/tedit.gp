##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	TEdit (Sample PC/GEOS application)
# FILE:		tedit.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "TEdit" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: tedit.gp,v 1.2 98/02/15 19:58:04 gene Exp $
#
##############################################################################
#
name tedit.app
#
longname "Text File Editor"
#
type	appl, process
#
class	TEProcessClass
#
appobj	TEApp
#
# This token must match both the token in the GenApplication and the token
# in the GenUIDocumentControl.
#
tokenchars "TeEd"
tokenid 0
heapspace	18785

# Increased stack size to 5K to fix bugs 27057/27058/27128 -atw (10/28/93)
stack 5000

#
library	geos
library	ui

ifdef _FAX_SUPPORT
library	mailbox
endif

#
resource AppLCMonikerResource lmem read-only shared
resource AppLMMonikerResource lmem read-only shared
resource AppSCMonikerResource lmem read-only shared
resource AppSMMonikerResource lmem read-only shared
resource AppYCMonikerResource lmem read-only shared
resource AppYMMonikerResource lmem read-only shared
resource AppSCGAMonikerResource lmem read-only shared

resource AppResource object
resource Interface object
resource DisplayUI object
resource DocumentUI object
resource StringsUI lmem read-only shared
#
# Exported entry points
#
export TEDocumentClass
export TELargeTextClass

ifdef _FAX_SUPPORT
export TEMailboxPrintControlClass
endif

