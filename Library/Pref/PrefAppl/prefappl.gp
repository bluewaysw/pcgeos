##############################################################################
#
# Copyright (c) 2026
#
# PROJECT:      Preferences
# MODULE:       PrefAppl
# FILE:         prefappl.gp
#
# Parameters file for prefappl.lib
#
##############################################################################

name prefappl.lib
longname "Applications Module"

tokenchars "PREF"
tokenid 0

type library, single, c-api

library geos
library ui
library config

resource BASEINTERFACE object read-only shared discardable
resource MONIKERRESOURCE lmem read-only shared
resource LISTMONIKERS lmem read-only shared

export PREFGETOPTRBOX
export PREFGETMODULEINFO

export PrefApplDialogClass
