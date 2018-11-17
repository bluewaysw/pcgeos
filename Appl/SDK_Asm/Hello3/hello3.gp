##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	
# FILE:		hello3.gp
#
# AUTHOR:	Allen Yuen, Jan 19, 1995
#
#
# This is the .gp file for out Hello3 app
#
#	$Id: hello3.gp,v 1.1 97/04/04 16:35:34 newdeal Exp $
#
##############################################################################
#
name	hello3.app

longname "Sample Hello3 Application"

type	appl, process

class	HelloProcessClass

appobj	HelloApp

tokenchars "HELO"
tokenid	0

library	geos
library	ui

resource HelloAppResource ui-object
resource HelloInterface ui-object
resource HelloStrings shared lmem read-only

export	HelloReplaceTriggerClass
