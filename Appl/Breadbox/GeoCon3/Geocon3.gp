# Project: Geocon 3.0
# Author: Originally Troy Sorrells, Now Lysle Shields of Breadbox Computer
# File: geocon30.gp

name geocon3.app
longname "GeoCon 3.0"
#longname "Configure"
tokenchars "gco3"
#tokenchars "NDCf"
tokenid 16431
type appl, process, single
class GeoConProcessClass
appobj GeoConApp
platform geos201
stack 6000

library geos
library ui
library ansic
library color

exempt color

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource INTERFACEDOS ui-object
resource INTERFACEUI ui-object
resource INTERFACESYSTEM ui-object
resource INTERFACEEXPRESS ui-object
resource INTERFACESTARTUP ui-object
resource INTERFACECOLOR ui-object
resource STARTUPFILEDIALOGRES ui-object
resource GUARDS ui-object
resource SELECTICONDIALOGRES ui-object
resource ADDFILENAMEMASKDIALOGRES ui-object
resource CHANGEEXECDIALOGRES ui-object
resource CHANGEPARAMDIALOGRES ui-object

resource MONIKERARTEGA1 lmem read-only shared ui-object
resource MONIKERARTEGA2 lmem read-only shared ui-object
resource MONIKERARTCGA lmem read-only shared ui-object
resource MONIKERARTHGC lmem read-only shared ui-object
resource DIALOGTEXT lmem read-only shared ui-object

export GeoConApplicationClass
export TitledItemClass
export TitledItemSizedClass
export ColorItemGroupClass
export INIGuardianClass
export INIStartupListClass
export INITokenListClass
export DOSTokenTriggerClass
export ChangeExecFileSelectorClass

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

