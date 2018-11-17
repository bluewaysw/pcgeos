#####################################################################
#
#  Copyright (C) 1996 Blue Marsh Softworks -- All Rights Resevered.
#
# PROJECT:       COMP 413 Software Engineering Project
# MODULE:        Geode Parameters
# FILE:          graph.gp
#
# AUTHORS:  Nathan Fiedler
#
# REVISION HISTORY:
#      Name     Date      Description
#      ----     ----      -----------
#       NF      03/07/96  Initial version
#
# DESCRIPTION:
#      This file contains the geode parameters for the Graph
#      application. This file is read by the GLUE linker to
#      build this application.
#
#####################################################################

name graph.app

longname "Graph"

type appl, process, single

class GProcessClass

appobj GApp

tokenchars "GRAF"
tokenid 16426

heapspace 380  # Not OmniGo
# heapspace 500  # OmniGo

platform geos201
# platform zoomer
# platform pt9000
# platform omnigo

library geos
library ui
library ansic
library spool

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource DOCGROUPRESOURCE object
resource DISPLAYRESOURCE ui-object discard-only

export GViewClass
export GDocumentClass

usernotes "SE Graph Application"

