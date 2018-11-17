##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		nonts.gp
#
# AUTHOR:	Adam de Boor, May  9, 1992
#
#
# Parameters for the non-task-switching task-switching driver
#
#	$Id: nonts.gp,v 1.1 97/04/18 11:58:16 newdeal Exp $
#
##############################################################################
#
name nonts.drvr
type driver, single, system

library geos

longname "Non-Switching Task Driver"
tokenchars "TSKD"
tokenid 0

#
# Special resource definitions
#

#
# this thing remains discarded until a DosExec takes place, at which point
# it comes in and gets modified. hence the swap-only
#
# It doesn't need to be marked as code, as it's copied into memory before
# being executed.
#
resource NTSExecCode shared swap-only

#
# used only by other people, and that seldom; no point in swapping it, and it
# never changes
#
resource NTSDriverInfoSegment shared lmem read-only discard-only

#
# used when forming block of data for DosExec, but never changed. since each
# session can perform only one DosExec, there's no point in swapping this thing
#
resource NTSStrings shared lmem read-only discard-only

#
# XIP-enabled
#
