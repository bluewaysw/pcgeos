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
resource DialogUI ui-object shared

#Libs
library geos
library ui
library ansic

# API functions
export GETTHOSETOOLS
export OPENWITHENTRYPOINT

# Not API
export CHECKIFUNSUPPORTEDFILES
export ISAPPONBLACKLIST
export LOADFILES
export LAUNCHAPP
export READAPPSFROMINIFILE
export READAPPSCALLBACK
#export WRITEINIFILE2

#classes
export OpenWithDialogClass
export AppDynamicListClass
export ConfigureDialogClass
