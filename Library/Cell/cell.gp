##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Cell Library
# FILE:		cell.gp
#
# AUTHOR:	John, 12/ 5/90
#
#	$Id: cell.gp,v 1.1 97/04/04 17:44:56 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name cell.lib

library geos

#
# Specify geode type
#
type	library, single

#
# Desktop-related things
#
longname	"Cell Library"
tokenchars	"CELL"
tokenid		0
#
# Define the library entry point
#
entry LibraryEntry

#
# Define resources other than standard discardable code
#
resource Init		code read-only shared
resource CellCode	code read-only shared
resource C_Cell		code read-only shared
#
# Export routines
#
export	CellReplace
export	CellGetDBItem

export	CellLock

export	CellGetExtent

export	RangeExists
export	RangeInsert
export	RangeSort
export	RangeEnum

export	RowGetFlags
export	RowSetFlags

# 
# C exported routines
#

export CELLLOCK
export CELLREPLACE
export CELLLOCKGETREF
export ROWGETFLAGS
export ROWSETFLAGS
export RANGEEXISTS
export RANGEENUM

#
# XIP-enabled
#
