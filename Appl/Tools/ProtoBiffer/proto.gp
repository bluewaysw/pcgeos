##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Tools/ProtoBiffer
# FILE:		protobiffer.gp
#
# AUTHOR:	Don Reeves: July 29, 1991
#
#
# Parameters file for: protob.geo
#
#	$Id: proto.gp,v 1.1 97/04/04 17:15:16 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name proto.app
#
# Specify geode type
#
type	process, appl
#
# Specify class name and application object for process
#
class	ProtoClass
appobj	ProtoApp
#
# Import library routine definitions
#
library	geos
library ui
#
# Desktop-related definitions
#
longname "Protocol Biffer"
tokenchars "PRBI"
tokenid 0
#
# Special resource definitions
#
resource Utils		fixed, code, read-only, shared
resource Interface	ui-object
resource Application	ui-object
resource Strings	lmem, read-only, shared
