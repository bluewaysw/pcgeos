##############################################################################
#
# PROJECT:      Map Heap Library -- memory allocation routines for the GPC
#               in it's video memory area.  Basically code written by Brian
#               and Allen that I've put into library.
# FILE:         mapheap.gp
#
# AUTHOR:       Lysle Shields
#
##############################################################################

name            mapheap.lib
longname        "Map Heap Library"
tokenchars      "MapH"
tokenid         0

type            library, single, c-api

library         geos

export   _MapHeapEnter
export   _MapHeapLeave
export   _MapHeapCreate
export   _MapHeapDestroy
export   _MapHeapMaybeInHeap
export   _MapHeapMalloc
export   _MapHeapFree
export   _MapHeapRealloc
export   _LMemLockAllocAndReturnError
export   _LMemLockReAllocAndReturnError
export   MapHeapWindowNumToPtr
export   MapHeapPtrToWindowNum

resource CommonCode fixed

