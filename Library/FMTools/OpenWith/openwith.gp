# who are we?
name openwith.lib

# for FileManager
longname    "OpenWith"
tokenchars  "FMTL"
tokenid     0

#Type
type    library, single, c-api

# Resources
resource FMUI lmem read-only shared
resource DialogUI object shared

#Libs
library geos
library ui
library ansic

# API functions
export GETTHOSETOOLS
export OPENWITHENTRYPOINT

#classes
export OpenWithDialogClass
export OpenWithContentClass
export AppDynamicListClass
export ConfigureDialogClass
export GeodeTokenTriggerClass