##############################################################################
#
#       Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:      PC GEOS
# MODULE:       ComponENT Object Library
# FILE:         ent.gp
#
# AUTHOR:       David Loftesness, Jun  1, 1994
#
#
# 
#
#       $Revision:   1.6  $
#
##############################################################################
#
# Permanent name
#
name ent.lib
#
# Long name
#
longname        "Component Object Library"
tokenchars      "ENT "
#
# Specify geode type
#
type    library, single
#
# Define library entry point
#
#entry  EntEntry

library geos
library ui
library basrun


ifdef DO_DBCS
platform pizza
exempt basrun
endif

#
# Define resources other than standard discardable code
#
nosort
resource EntCode code read-only shared


export EntClass
export EntVisClass
export ML1Class
export ML2Class
export EntDispatchSetProperty
export EntDispatchGetProperty
export ENTDISPATCHSETPROPERTY
export ENTDISPATCHGETPROPERTY
export EntGetVMFile
export ENTGETVMFILE
export EntCreateComplexHeader
export EntResolvePropertyAccess
export ENTRESOLVEPROPERTYACCESS

export EntSetPropertyInTable
export EntGetPropertyFromTable
export EntDispatchAction
export EntResolveAction
export EntAppClass

export EntUtilCheckClass
export EntCallParent
export EntGetPropNameAndDataCommon

export EntUtilGetProperty
export EntUtilSetProperty
export EntResolvePropertyCommon
export EntResolveActionCommon
export EntUtilDoAction

export ENTDISPATCHACTION












