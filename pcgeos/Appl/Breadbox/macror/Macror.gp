name macror.app

longname "Macro Recorder"

tokenchars "MCRD"
tokenid 16431

type    appl, process, single
class   MonitorProcessClass
appobj  MonitorApp

export  MonitorApplicationClass

platform geos201

library geos
library	ui
library ansic

resource APPRESOURCE object
resource INTERFACE object
resource MACROENG_FIXED code read-only shared fixed
resource DOCUMENTRESOURCE object

stack 4000

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"
