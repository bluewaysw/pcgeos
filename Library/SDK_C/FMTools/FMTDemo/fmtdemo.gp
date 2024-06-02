# who are we?
name fmtdemo.lib

# for FileManager
longname    "FileMangerTool Demo"
tokenchars  "FMTL"
tokenid     0

#Type
type    library, single, c-api

# Resources
resource FMTData lmem read-only shared
resource DialogUI ui-object shared

#Libs
library geos
library ui
library ansic

# API functions
export GETTHOSETOOLS
export DEMOTOOLSTART

# Not API
export FMTDemoInteractionClass