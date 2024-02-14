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
#	$Id: inkfix.gp,v 1.1 97/04/05 01:06:35 newdeal Exp $
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

entry	HostIfEntry

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
