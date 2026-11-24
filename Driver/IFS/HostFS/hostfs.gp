##############################################################################
#
#	Copyright (c) blueway.Softworks 2026 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	File Systems
# FILE:		hostfs.gp
#
# DESCRIPTION:
#	Host file system driver for pcgeos-basebox: serves a host directory
#	as a live, writable GEOS drive through the BASEBOX host interface.
#
##############################################################################
#
name hostfs.ifsd
type driver, single system
library geos
library hostif
#
# Desktop-related things
#
longname "Host IFS Driver"
tokenchars "HFSD"
tokenid 0
#
# Special resource definitions
#
resource Resident fixed code shared read-only
resource Init code shared read-only discard-only
resource DriverExtendedInfo lmem shared read-only
