##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Libraries -- Common Swap Driver Routines
# FILE:		swap.gp
#
# AUTHOR:	Adam de Boor, June  17, 1990
#
#
#	$Id: swap.gp,v 1.1 97/04/07 11:15:48 newdeal Exp $
#
##############################################################################
#
# Specify name of geode
#
name swap.lib
#
# Specify type of geode
#
type library, single, system
entry SwapEntry
#
# Import kernel routine definitions
#
library geos
#
# Desktop-related things
#
longname	"Swap Driver Library"
tokenchars	"MEMD"
tokenid		0
#
# Override default resource flags
#
resource Resident	shared, read-only, code, fixed
resource Init		preload, shared, read-only, code, discard-only
#
# Export routines
#
export	SwapInit
export	SwapWrite
export	SwapRead
export	SwapFree

#
# additions for letting the swap drivers function without
# the kernel being resident in memory (for geosts driver)
#
incminor
export	SwapLockDOS
export	SwapUnlockDOS
export	SwapIsKernelInMemory?
export	SwapSetKernelFlag
export	SwapClearKernelFlag
export	SwapCompact

#
# XIP-enabled
#
