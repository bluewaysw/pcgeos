##############################################################################
#
#       Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:      PC/GEOS
# MODULE:       LEGOS - UI Builder
# FILE:         bent.gp
#
# AUTHOR:       Martin Turon, Sep  8, 1994
#
#	$Id: bent.gp,v 1.1 98/03/11 15:09:47 martin Exp $
#       $Revision: 1.1 $
#
##############################################################################
#
#
# Permanent name
#
name bent.lib
#
# Long name
#
longname        "Build-time Component Library"
tokenchars      "BENT"
#
# Specify geode type
#
type    library, single

library geos
library ui
library ent
library ansic
library basco
library basrun
library gadget

#ifdef DO_DBCS
#platform pizza
#else
#platform zoomer
#endif

exempt geos
exempt ui
exempt gadget
exempt basco
exempt basrun
exempt ansic
exempt ent

#
# Define resources other than standard discardable code
#
#resource        BENTPROPERTYTOOLUIRESOURCE      ui-object read-only shared
#resource        BENTPROPERTYTOOLBOXUIRESOURCE   ui-object read-only shared


#
# Don't forget to export *all* classes defined in bent
#
export BentClass
export BentNodeClass
export BentWindowClass
export BentViewClass
export BentManagerClass

#export BentCreateControlClass

export GenEmbeddedCodeClass
export GenCTriggerClass

#
# Export all external routines.
#

#export BentFindChildUnderPoint
skip 1
export BentFindClassPtrStruct

export BentCopyEvents
export BentEnsureBufferSpace
export BentLockDescription
export BentGetComponentPropertyUnquoted
export BentGetComponentName
export BentExtractPropertyArrayElement
export BENTPROCESSPROPERTYARRAYELEMENT

export ECCheckPSelf
export BentGetDescriptionFlags
incminor
export BentUnlockDescription

resource PointerImages data read-only shared
