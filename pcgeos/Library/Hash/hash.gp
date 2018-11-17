##############################################################################
#
#	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	Legos
# MODULE:	Hash library
# FILE:		hash.gp
# AUTHOR:	Paul L. DuBois
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dubois	11/ 7/94	Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: hash.gp,v 1.1 97/05/30 06:45:54 newdeal Exp $
#
###############################################################################
name	hash.lib

library	geos

type	library,single

# Desktop-related things
longname	"Hash Library"
tokenchars	"hemp"
tokenid		0

# Exported hash things
export HashTableCreate
export HashTableAdd
export HashTableRemove
export HashTableLookup
export HashTableHash

# Exported mini-heap things
export MiniHeapCreate
export MHAlloc
export MHFree

# EC routines
export ECCheckMiniHeap
export ECCheckChunklet
export ECCheckUsedChunklet
export ECCheckHashTable

export HASHTABLECREATE
export HASHTABLELOOKUP
export HASHTABLEREMOVE
export HASHTABLEADD
export HASHTABLEHASH

export HashTableResize
export HASHTABLERESIZE
export MHMarkFree
export MHRestoreFree
