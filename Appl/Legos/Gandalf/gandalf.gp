##############################################################################
#
#       Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:      PC/GEOS
# MODULE:       Appl -- UIBuilder
# FILE:         uibuilder.gp
#
# AUTHOR:       Martin Turon, Aug 29, 1994
#
#
#       $Id: gandalf.gp,v 1.2 98/10/13 22:15:34 martin Exp $
#
##############################################################################
#
name            gandalf.app

longname         "NewBASIC Builder"
type            appl, process, single

class           BuilderProcessClass
appobj          BuilderApp

tokenchars      "BLDR"
tokenid         0


#
# Libraries: list which libraries are used by the application.
#
library         geos
library         ui
library         ansic
library         ent
library         bent
library         basco
library         basrun
library         bgadget
library         gadget
library         borlandc

#ifdef ZOOMER
#platform zoomer
#exempt basco
#exempt bent
#else
#platform geos201
#exempt basco
#exempt bent
#exempt basrun
#exempt ansic
#exempt bgadget
#exempt gadget
#exempt ent
#endif

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource        AppResource     object
resource        Interface       object
resource        Interpreter     object
resource        EditorInterface object



#
# Moniker resources
#
#resource APPLCMONIKERRESOURCE lmem read-only shared
#resource APPLMMONIKERRESOURCE lmem read-only shared
#resource APPSCMONIKERRESOURCE lmem read-only shared
#resource APPSMMONIKERRESOURCE lmem read-only shared
#resource APPYCMONIKERRESOURCE lmem read-only shared
#resource APPYMMONIKERRESOURCE lmem read-only shared
#resource APPSCGAMONIKERRESOURCE lmem read-only shared

#resource APPTCMONIKERRESOURCE lmem read-only shared
#resource APPTMMONIKERRESOURCE lmem read-only shared
#resource APPTCGAMONIKERRESOURCE lmem read-only shared

resource        MonikerResource lmem read-only shared
#resource        GANDALFCLASSSTRUCTURES fixed read-only shared
#
# Exported Classes
#
export  BuilderTextClass
export  EditorTextClass
export  RoutineListClass
export  BuilderShellClass
export  CallStackListClass
export  VarUpdateInteractionClass
export  VarChartClass
export  BuilderAppClass
export  ComponentListClass
export  BuilderManagerClass
export  EventListClass
export  BuilderComponentClass
export  UpdatingGenInteractionClass

#
# The stack really needs to be 8k.
#
stack   8096


