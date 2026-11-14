##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	
# FILE:		browser.gp
#
# AUTHOR:	
#
#
# 
#
#	$Id: browser.gp,v 1.3 98/08/18 16:11:01 edwin Exp $
#
##############################################################################

name gpcbrowser.app
longname "Global Internet"
tokenchars "GPCB"

tokenid 0
stack 8000

type	appl, process, single
class	GPCProcessClass
appobj	GPCApp

library	geos
library	ui
library ansic
library spool
library socket
library text
library math
library www2

resource APPRESOURCE   ui-object
resource BINTERFACE    ui-object
resource GENERICUI     ui-object
resource PAGEMENURESOURCE  ui-object
resource ICONSRESOURCE ui-object

#
# Its a good size for a wireless web browser. Also, 300K is used
# by infoserv as the threshold to stop loading large pages.
#
heapspace 300K

export	GPCProcessClass
export	GPCAppClass
export	ISDialogClass
export	ISAlternateTriggerClass
export	ISPageSetupGenInteractionClass
export	ISTextClass
export	ISValueClass
export	ISGenViewClass
export	ISPrintCtrClass
export	ISDynamicListClass
export	ISConfigToolbarGenInteractionClass
