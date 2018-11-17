##############################################################################
#      Copyright 1994-2002  Breadbox Computer Company LLC
#
# PROJECT:	Anarchy
# MODULE:	Spider
#
# FILE:		spider.gp
#
# AUTHOR:	jfh 12/02
#
#              
##############################################################################

name spider.app

longname "Spider"

type	appl, process, single

class	SpiderProcessClass

appobj	SpiderApp

tokenchars "SpS1"
tokenid 16431

stack 4000

platform geos201

library	geos
library	ui
library cards
library color
library sound

exempt cards
exempt color
exempt sound

resource APPRESOURCE	ui-object
resource INTERFACE	ui-object
resource TABLERESOURCE	object

export SpiderClass
export DealDeckClass
export WorkDeckClass
export DoneDeckClass

usernotes "Copyright 1994-2003  Breadbox Computer Company LLC  All Rights Reserved"






