##############################################################################
#
#       Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:      PC GEOS
# MODULE:       
# FILE:         
# AUTHOR:       jimmy lefkowitz
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       jimmy   5/ 5/89         Initial Revision
#
# DESCRIPTION:
#       
#
#	$Id: bastest.gp,v 1.2 98/10/16 00:08:52 martin Exp $
#       $Revision: 1.2 $
#
###############################################################################
name bastest.app
longname "Basic Interpreter Test App"
tokenchars "GDSC"
tokenid 0
type    appl, process, single
class   BasicTestProcessClass
appobj  BasicTestApp

library geos
library ui
library ansic
library basco
library math
library basrun
library ent
library gadget
library bgadget

resource APPRESOURCE    object
resource INTERFACE      object

stack   8192

#platform geos201

export BasicTestApplicationClass

#exempt ansic
#exempt legos
#exempt basco
#exempt basrun
#exempt gadget
#exempt bgadget
#exempt ent
