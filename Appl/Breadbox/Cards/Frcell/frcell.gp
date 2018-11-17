##############################################################################
#      Copyright 1994-2002  Breadbox Computer Company LLC
#
# PROJECT:	Anarchy
# MODULE:	FreeCell  (porting from a previous ESP anarchy project using
#                      Nate's cards.goh header file)
# FILE:		freecell.gp
#
# AUTHOR:	jfh 12/02
#
#              
##############################################################################

name frcell.app

longname "FreeCell"

type	appl, process, single

class	FreeCellProcessClass

appobj	FreeCellApp

tokenchars "FCL1"
tokenid 16431

stack 4000

platform geos201

library	geos
library	ui
library ansic
library cards
library color

exempt cards
exempt color

resource APPRESOURCE	ui-object
resource INTERFACE	ui-object
resource TABLERESOURCE	object

export FreeCellApplicationClass
export FreeCellClass
export WorkDeckClass

usernotes "Copyright 1994-2003  Breadbox Computer Company LLC  All Rights Reserved"






