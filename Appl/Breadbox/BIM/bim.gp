name bim.app
longname "Instant Messenger"

type appl, process, single

class AIMProcessClass
appobj AIMApp

tokenchars "BIM1"
tokenid 16431

stack 4096

library geos
library ui
library socket
library ansic
ifdef USE_TREE
library extui
endif
library sound   # We make explicit use of the Sound...MusicLMem routines.
library parentc

# Icons
#resource APPLCMONIKERRESOURCE ui-object read-only shared
#resource APPLMMONIKERRESOURCE ui-object read-only shared
#resource APPSCMONIKERRESOURCE ui-object read-only shared
#resource APPSMMONIKERRESOURCE ui-object read-only shared
#resource APPLCGAMONIKERRESOURCE ui-object read-only shared
#resource APPSCGAMONIKERRESOURCE ui-object read-only shared
#resource APPTCMONIKERRESOURCE ui-object read-only shared
#resource APPTMMONIKERRESOURCE ui-object read-only shared
#resource APPTCGAMONIKERRESOURCE ui-object read-only shared
#resource ICONRESOURCE data read-only shared # These are copied by process
resource APPMONIKERRESOURCE ui-object read-only shared

# UI objects
resource AppResource ui-object
resource Interface ui-object
resource LoginResource ui-object
resource ConfigResource ui-object
resource IMWindowResource ui-object read-only

# Sounds
resource TocNoiseResource data lmem read-only shared

export IMPrimaryClass
export IMWindowTextClass
export GenTextLimitClass
export ConfigListClass
export GenInteractionExClass
export GenTriggerExClass
export AimCancelTriggerClass
ifndef USE_TREE
export GenSimpleTreeListClass
endif

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"
