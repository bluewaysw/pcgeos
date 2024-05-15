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

# ----- RSOKED/TokShiow Ressourcen
resource DialogBoxResource      ui-object read-only shared
resource DataResource      lmem read-only shared
resource TemplateResource	ui-object read-only shared
resource TSDataResource      lmem read-only shared
# ----- 

#Libs
library geos
library ui
library ansic

# API functions
export GETTHOSETOOLS
export FOLDEREDTOOLSTART

# Not API
export FolderEdInteractionClass


# ----- ReToked Libary Krams
export WordValueClass
export IE_DialogClass

# ----- Routinen werden erst von Library exportiert
# export ICONEDITSELECTTOKENDIALOG
# export ICONEDITSELECTTOKEN
# export ICONEDITTOKENDELETER

# export ICONEDITATTACHFLAGSELECTOR
# export ICONEDITGETFLAGSFROMSELECTOR
# export ICONEDITSETFLAGSOFSELECTOR

