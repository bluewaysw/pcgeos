##############################################################################
#
#	Copyright (c) blueway.Softworks 2023 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# FILE:		hostif.gp
#
# AUTHOR:	Falk Rehwagen, 12/23
#
#
# Parameters file for: hostif
#
#	$Id: hostif.gp,v 1.1 23/12/05 01:06:35 bluewaysw Exp $
#
##############################################################################
#
# Permanent name
#
name hostif.lib
#
# Long name
#
longname "Host Interface Library"
#
# DB Token
#
tokenchars "HSTI"
tokenid 0

#
# Specify geode type
#
type	library, single

#
# Import kernel routine definitions
#
library	geos

#
# Exported routines (and classes)
#
export HostIfDetect
export HOSTIFDETECT
export HostIfCall
export HOSTIFCALL
