#####################################################################
#
#       Copyright (c) Geoworks 1996 -- All Rights Reserved.
#
# PROJECT:      Simple Word Processor
# MODULE:       Geode Parameters
# FILE:         simpwp.gp
#
# AUTHOR:       Lawrence Hosken
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       LH                      Initial version
#       NF      9/23/96         Corrected heapspace value,
#                               made tokenchars unique
#	RainerB	8/6/2022	Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:
#       This file contains Geode definitions for the SimpWP sample
#       application. This file is read by the GLUE linker to
#       build this application.
#
# RCS STAMP:
#       $Id: simpwp.gp,v 1.1 97/04/04 16:37:15 newdeal Exp $
#
#####################################################################

name     simpwp.app
longname "Simple Word Processor"

type	appl, process, single
class	SWPProcessClass
appobj	SWPApp

tokenchars "SMWP"
tokenid    8

heapspace 765

library	geos
library	ui
library text

resource AppResource      ui-object
resource Interface        ui-object
resource DocGroupResource object
resource DisplayResource  ui-object read-only shared
resource TemplateResource object read-only shared

export SWPDocumentClass

