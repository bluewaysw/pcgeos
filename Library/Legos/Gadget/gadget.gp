##############################################################################
#
#       Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:      Visual Geos
# MODULE:       gadget
# FILE:         gadget.gp
#
# AUTHOR:       David Loftesness, Jun  1, 1994
#
#
# 
#
#       $Id: gadget.gp,v 1.1 98/03/11 04:34:08 martin Exp $
#
##############################################################################
#
# Permanent name
#
name gadget.lib
#
# Long name
#
longname        "Gadget Library"
tokenchars      "CoOL"
#
# Specify geode type
#
type    library, single
#
# Define library entry point
#

library geos
library ui
library ent
library pen
library basrun
library	text
library ansic

ifdef DO_DBCS
platform pizza
exempt ui
else
#platform zoomer
#exempt text
endif

#exempt ent
#exempt basrun
# dont depend on text so custom filters can work on post 2.1 text lib

#
# Define resources other than standard discardable code
#
nosort
resource GadgetCode code read-only shared
resource GadgetListCode code read-only shared
resource Strings data read-only shared
#
# Exported routines (and classes)
#
#export EOLRESOLVECLASSREFERENCE
export GadgetClassPtrTable
export GadgetClass
export GadgetGeomClass
export GadgetAggClass
export GadgetButtonClass
export GadgetEntryClass
export GadgetFormClass
export GadgetNumberClass
export GadgetGroupClass
skip 1
export GadgetLabelClass
export GadgetListClass
export GadgetDialogClass

# Unused so taken out for efficiency. -jmagasin 6/19/96
#export GadgetFigClass
skip 1


# GadgetSoundClass
skip 1
export GadgetTextClass
export GadgetToggleClass
export GadgetChoiceClass
export GadgetFloaterClass
export GadgetClipperClass
export GadgetGadgetClass
export GadgetSpacerClass
export GadgetPictureClass
export ServiceTimeDateClass

# replace alarm class
# export ServiceAlarmClass
export ServiceAlarmClientClass

export ServiceTimerClass
export GadgetPopupClass
export GadgetScrollbarClass
export GadgetTableClass
export ServiceClipboardClass

export LegosAppClass

export TextIsInViewFar as TextGetView
export TextIsInViewFar as TEXTGETVIEW
export GadgetDBClass

export SystemDisplayClass
export SystemBusyClass
export SystemSoundClass

export AlarmServerClass
