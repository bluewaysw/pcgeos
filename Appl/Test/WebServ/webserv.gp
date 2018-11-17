##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	GEOS Web Server
# FILE:		webserv.gp
#
# AUTHOR:	Allen Yuen, Sep 25, 1995
#
#
# This is the .gp file for the GEOS Web Server
#
#	$Id: webserv.gp,v 1.1 97/04/04 15:09:36 newdeal Exp $
#
##############################################################################
#
name	webserv.app
longname "GEOS Web Server"
type	appl, process, single
class	WebServProcessClass
appobj	WebServApp
tokenchars "WSRV"
tokenid	0

#
# A total random guess for now.
#
heapspace 5K

library	geos
library	ui
library	socket
resource WebServClassStructures fixed data read-only shared
resource FixedCode fixed code read-only shared
resource AppResource ui-object
resource Interface ui-object
