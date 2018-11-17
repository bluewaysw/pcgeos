##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	
# FILE:		songlist.gp
#
# AUTHOR:	Chung Liu, Dec  1, 1994
#
#
# 
#
#	$Id: songlist.gp,v 1.1 97/04/04 16:40:13 newdeal Exp $
#
##############################################################################
#
name songlist.app
longname "Song List"
#
tokenchars "SNGL"
tokenid 8
#
type appl, process, single
class SLProcessClass
appobj SLApp
#
library geos
library ui
library ansic
library mailbox

#
resource APPRESOURCE ui-object
resource INTERFACE ui-object
#
export SLSendControlClass


