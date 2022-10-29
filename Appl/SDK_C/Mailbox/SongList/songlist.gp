##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	
# FILE:		songlist.gp
#
# AUTHOR:	Chung Liu, Dec  1, 1994
#
#       Name    Date            Description
#       ----    ----            -----------
#       CL	1/12/94		Initial version
#	RainerB	4/27/2022	Resource names adjusted for Watcom compatibility
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
resource AppResource ui-object
resource Interface ui-object
#
export SLSendControlClass


