##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	    Sample notepad library
# MODULE:	    SDK
# FILE:         notelib.gp
#
# AUTHOR:	    EBallot: July 1996
#
# DESCRIPTION:
#	geode parameters file for Notepad sample library
#
# $Id: notelib.gp,v 1.1 97/04/07 10:43:59 newdeal Exp $
#
##############################################################################
#

# Permanent name:
name notelib.lib

# Long filename:
longname    "Notepad Library Sample"
tokenchars	"NLIB"
tokenid     8

# Specify geode type: is a library
#
type	library, single

# Libraries: list which libraries are used by this library
#
library geos
library ui
library pen
library text

# Resources: this resource contains the template objects which will be
#            copied into the application that used NotepadClass
#
resource NOTEPADTEMPLATE object read-only shared discardable

# Exportables
#
export NotepadClass


