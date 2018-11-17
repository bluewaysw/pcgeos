name home.app
#
longname "Home Automation"
#
type   appl, process, single
heapspace 6200
stack 4000
class   HomeProcessClass
appobj  HomeApp
#
tokenchars "HOME"
tokenid 16431

platform geos201

library geos
library ui
library ansic
library color
library spool
library math
library text
exempt color

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource MENURESOURCE ui-object
resource FILEMENU ui-object
resource DOCUMENTUI object
resource HOMEAPPMONIKERRESOURCE data
resource HOMEDOCMONIKERRESOURCE data object
resource TRIGGERMONIKERRESOURCE swap-only ui-object
resource TRIGGERBWMONIKERRESOURCE swap-only ui-object
#resource BREADBOXMONIKERRESOURCE swap-only ui-object
#resource BREADBOXMONIKERRESOURCE2 swap-only ui-object
resource INVISDIALOGRESOURCE ui-object
resource EVENTDIALOG swap-only ui-object
resource DROPDOWNLISTS swap-only ui-object
resource ICONEDITOR swap-only ui-object
resource POINTERS ui-object read-only

export HomeDocumentClass
export HomeGroupClass
export HomeUnitClass
export HomeRoomClass
export HomeValueClass
export HomeBooleanGroupClass
export IconClass

usernotes "Copyright 1994 - 2002   Breadbox Computer Company LLC  All Rights Reserved"

