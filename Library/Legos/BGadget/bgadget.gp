##############################################################################
#
#       Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:      PC/GEOS
# MODULE:       LEGOS - UI Builder
# FILE:         BGadget.gp
#
# AUTHOR:       Martin Turon, Sep  8, 1994
#
#
#       $Id: bgadget.gp,v 1.1 98/03/12 19:51:13 martin Exp $
#
##############################################################################
#
#
# Permanent name
#
name bgadget.lib
#
# Long name
#
longname        "BGadget Library"
tokenchars      "BoOL"
#
# Specify geode type
#
type    library, single

library geos
library ui
library ansic
library ent
library bent
library gadget
library	basrun

ifdef DO_DBCS
platform pizza
exempt ent
exempt bent
exempt gadget
exempt basrun
endif

#
# UI resources for BuilderCreateControlClass
#
#resource        BGADGETCREATETOOLUIRESOURCE        ui-object read-only shared
#resource        BGADGETCREATETOOLBOXUIRESOURCE     ui-object read-only shared
#resource        BGADGETCREATETOOLMONIKERRESOURCE   lmem read-only shared


#
# Define resources other than standard discardable code
#
export BGadgetClassPtrTable

#export BGadgetCreateControlClass
#export BGadgetMonikerControlClass
#export BGadgetGeometryControlClass

export BGadgetClass
export BServiceClass
export BGadgetWinClass
export BGadgetButtonClass
export BGadgetFormClass
export BGadgetNumberClass
export BGadgetEntryClass
export BGadgetGroupClass
export BGadgetLabelClass
export BGadgetListClass
export BGadgetDialogClass

# Unused, so removed for efficiency. -jmagasin 6/19/96
#export BGadgetFigClass
skip 1

# BGadgetSoundClass
skip 1
export BGadgetPopupClass
export BGadgetScrollbarClass
export BGadgetLookClass
export BGadgetAggClass
