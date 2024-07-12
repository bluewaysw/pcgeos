##############################################################################
#
#       Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:      Legos
# MODULE:       Tree library
# FILE:         tree.gp
#
# AUTHOR:       Roy
#
# DESCRIPTION:
#       
#       General tree
#
#	$Id: tree.gp,v 1.1 97/05/30 08:20:10 newdeal Exp $
#
##############################################################################
#
#
#
name tree.lib

longname        "Tree Library"
tokenchars      "TREE"
tokenid         0

#
# Specify geode type: is a library
#
type    library, single, c-api

entry   TREELIBRARYENTRY
#
# Make compatible with Geos 2.01
#
platform	geos201

#
# Libraries: list which libraries are used by the application.
#
library geos
library ansic

ifdef ZOOMER
platform zoomer
exempt ansic
endif

export HugeTreeCreate
export HugeTreeDestroy
export HugeTreeAddAfterNthChild
export HugeTreeAppendChild
export HugeTreeSetNthChild
export HugeTreeRemoveNthChild
export HugeTreeAllocNode
export HugeTreeGetNthChild
export HugeTreeGetParent
export HugeTreeGetNumChildren
export HugeTreeGetNumSibling
export HugeTreeGetDataSize
export HugeTreeLock

# Defined as macros:
# HugeTreeUnlock
# HugeTreeDirty
