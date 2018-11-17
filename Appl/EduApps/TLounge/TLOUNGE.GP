# Copied from Meeting Room v1.4 0-3 of 11 Jun 99

# Meeting Room (freebie) names...
  name tlounge.app
  longname "Teacher's Lounge"

type    appl, process, single
class   IRCProcessClass
appobj  IRCApp
# Meeting Room (freebie) token... added tiny icon
  tokenchars "TLa1"
tokenid 16431
stack 8000

library geos
library ui
library socket
library ansic
library text
library accpnt

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource EXPIREDIALOGRESOURCE ui-object
resource ICONS ui-object lmem read-only shared
resource LOGORESOURCE ui-object lmem read-only shared
resource ABOUTRESOURCE ui-object
resource TEXTSTRINGS data object

export GenTextLimitClass
export NickGenTextClass
export SortDynamicListClass
export ExpireDialogClass

usernotes "Copyright 1994-2004 - Breadbox Computer Company LLC  All rights Reserved"

