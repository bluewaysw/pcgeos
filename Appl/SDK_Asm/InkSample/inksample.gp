##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	InkSample
# FILE:		inkSample.gp
#
# AUTHOR:	Allen Yuen, Jan 24, 1994
#
#
# This is the .gp file for our InkSample app
#
#	$Id: inksample.gp,v 1.1 97/04/04 16:35:26 newdeal Exp $
#
##############################################################################
#
name	inksamp.app

longname "Sample Ink App"

type	appl, process

class	InkSampleProcessClass

appobj	InkSampleApp

tokenchars "ISMP"
tokenid	0

library	geos
library	ui

resource InkSampleAppResource ui-object
resource InkSampleInterface ui-object
resource InkSampleStrings shared lmem read-only

export	InkSampleTriggerClass
export	InkSampleCopyTriggerClass
