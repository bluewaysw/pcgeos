##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		kerr.gp
#
# AUTHOR:	Tony, 10/89
#
#
# Parameters file for: kerr.geo
#
#	$Id: kerr.gp,v 1.1 97/04/04 16:58:22 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name kerr.app
#
# Long name
#
longname "Kernel Error Tester"
#
# Specify geode type
#
type	appl, process, single
#
# Specify class name for process
#
class	kerr_ProcessClass
#
# Specify application object
#
appobj	MyApp
tokenchars "KERR"
tokenid 0
#
# Import library routine definitions
#
library	geos
library	ui
#
# Define resources other than standard discardable code
#
resource Interface object
