##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Serial (Sample GEOS application)
# FILE:		serial2.gp
#
# AUTHOR:	Ed Ballot
#
# DESCRIPTION:	This sample application illustrates use of
#		event driven serial notification
#
# RCS STAMP:
#	$Id: serial2.gp,v 1.1 97/04/04 16:39:11 newdeal Exp $
#
##############################################################################

name     serial2.app
longname "Serial Demo"

type	appl, process, single
class	SerialDemoProcessClass
appobj	SerialDemoApp

tokenchars "SAMP"
tokenid    8

library	geos
library	ui
library ansic
library	streamc

resource APPRESOURCE	ui-object
resource INTERFACE	ui-object
resource SERIALSETTINGS ui-object
resource CONSTANTDATA	shared lmem read-only

export SerialTriggerClass
export SerialTextDisplayClass
