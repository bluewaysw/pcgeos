##############################################################################
#
# PROJECT:	
# FILE:		idial.gp
#
# AUTHOR:	Mingzhe Zhu, Nov 21, 1998
#
#
# 
#
#	$Id: $
#
##############################################################################

name IDialup.app
longname "Dial-up & Configure"
tokenchars "IDIA"

tokenid 0
stack 2000

type	appl, process, single
class	IDialupProcessClass
appobj	IDialupApp

library	geos
library	ui
library ansic
library socket
library accpnt

resource AppResource   ui-object
resource Interface    ui-object
resource DBInterface    ui-object
resource InfoResource    ui-object
resource OtherResource    ui-object
resource StringResource    lmem   shared read-only

heapspace 500K

export	IDialupProcessClass
export	IDialupAppClass
export	IDialupInfoClass
export  IDialupPrimaryClass
export	IDialupIPTextClass
export	IDialupInteractionClass
