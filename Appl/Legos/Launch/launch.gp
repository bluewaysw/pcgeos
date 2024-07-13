##############################################################################
#
#       Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:      L E G O S
# MODULE:       
# FILE:         
# AUTHOR:       Roy Goldman
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#
#
# DESCRIPTION:
#       
#
#	
#
#       $Revision:   1.3  $
#
###############################################################################
name claun.app
longname "Legos Launcher"
tokenchars "LAUN"
tokenid 0
type    appl, process, single
class   LaunchProcessClass
appobj  LaunchApp

library ansic
library gadget
library geos
library ui
library	basrun
library ent

resource APPRESOURCE    object
stack	8192
