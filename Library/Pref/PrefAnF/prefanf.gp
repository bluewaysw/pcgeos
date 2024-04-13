#
# Basics
#
name prefanf.lib
longname "Apps 'n Files Module"
tokenchars "PREF"
tokenid 0

#
# Type
#
type    library, single, c-api

#
# Libraries: list which libraries are used by the application.
#
library geos
library ui
library ansic
library config

#exempt ansic

#
# Resources
#
resource BASEINTERFACE          read-only shared discardable
resource MONIKERRESOURCE        lmem read-only shared

#
# Routines
#
export  PREFGETOPTRBOX
export  PREFGETMODULEINFO

#
# These are the classes exported by the library
#
export  PrefDialogMMClass
export  PrefAppListClass

