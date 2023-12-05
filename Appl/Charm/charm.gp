#####################################################################
#
# PROJECT:      Character Map
# MODULE:       Geode Parameters
# FILE:	        charm.gp
#
# AUTHOR:       Nathan Fiedler
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       NF      9/23/96         Initial version
#	RainerB	12/05/2023	Some changes for FreeGEOS 6.0 release.
#				See app.goh for details
#
# DESCRIPTION:
#       This file contains Geode definitions for the "CharMap"
#       application. This file is read by the GLUE linker to
#       build this application.
#
#####################################################################

name     charm.app
longname "Character Map"

type   appl, process, single
class  CMProcessClass
appobj CMApplication

tokenchars "CHRm"
tokenid    16426

# Desktop heapspace
heapspace 3773
# Zoomer heapspace
# heapspace 3978
# OmniGo heapspace
# heapspace 14K

# platform geos201
# platform zoomer
# platform pt9000
# platform omnigo

library geos
library ui
library text
library ansic

resource Application        ui-object
resource Interface          ui-object
resource Content            object
resource AppMonikerResource lmem read-only shared
resource DataResource lmem read-only shared

export CMMapClass
export CMRowClass
export CMTextClass
export CMGenPrimaryClass

usernotes "Character Map - Get quick access to all characters of a font.\rFreeGEOS version 6"

