#####################################################################
#
#   Copyright (c) 1996 Geoworks, Inc. -- All Rights Reserved.
#
# PROJECT:	Error-Checking Sample
# MODULE:	Geode Parameters
# FILE:		ec.gp
#
# AUTHORS:      Lawrence Hosken
#               Nathan Fiedler
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	LH	4/14/93       	Initial MyChart #4 sample
#	NF	8/9/96		Made into EC sample
#
# DESCRIPTION:
#	These are the parameters for the glue linker which describe
#	how the geode should be built.
#
# $Id: echeck.gp,v 1.1 97/04/04 16:41:30 newdeal Exp $
#
#####################################################################

name     echeck.app
longname "Error Check"

type	appl, process, single
class	EChkProcessClass
appobj	EChkApp

tokenchars "SAMP"
tokenid    8

heapspace 5k

library	geos
library	ui

resource APPLICATION ui-object
resource INTERFACE   ui-object
resource DOCGROUP    object
resource DISPLAY     ui-object read-only shared
resource CONTENT     object read-only shared
resource STRINGS     lmem shared read-only

export EChkProcessClass
export EChkChartClass
export EChkDocumentClass

usernotes "Error Check sample application."

