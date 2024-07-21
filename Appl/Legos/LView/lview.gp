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
#	$Id: lview.gp,v 1.3 98/10/14 02:13:54 martin Exp $
#
###############################################################################
name lview.app
longname "Legos Viewer App"
tokenchars "LVie"
tokenid 0
type    appl, process, single
class   LViewProcessClass
appobj  LViewApp

library geos
library ui
library ansic
library	basrun
library basco
library math
library	gadget		# For LegosAppClass.
library ent		# For EntAppClass

resource AppResource    object
resource Interface      object
resource lvhack_TEXT	fixed code read-only shared

export  LViewInterpClass
export LViewAppClass
#export LegosAppClass
stack	8096
