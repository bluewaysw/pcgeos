##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	
# FILE:		infoserv.gp
#
# AUTHOR:	Mingzhe Zhu, Aug 21, 1996
#
#
# 
#
#	$Id: browser.gp,v 1.1 97/04/04 17:20:34 newdeal Exp $
#
##############################################################################

name browser.app
longname "Browser"
tokenchars "BRWS"
tokenid 11

type	appl, process, single
class	ISProcessClass
appobj	ISApp

library	geos
library	ui
library ansic

library htcore
library http
library htmlp
library pmanager
library uigenera

resource APPRESOURCE   ui-object
resource INTERFACE    ui-object
resource CONTENT       ui-object
resource MENURESOURCE  ui-object
resource ICONSRESOURCE ui-object
resource UIGENERATORRES	ui-object

export	ISProcessClass
export	ISAppClass

export 	HTPlainClass
export 	HTMLClass
export  ISPresentationManagerClass






