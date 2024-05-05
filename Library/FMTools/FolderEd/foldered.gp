# who are we?
name foldered.lib

# for FileManager
longname    "FolderEdTool"
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
export FOLDEREDTOOLSTART

# Not API
export FolderEdInteractionClass