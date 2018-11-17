name thinker.app
longname "Thinker Pro"
type    appl, process, single
class   ThinkerProcessClass
appobj  ThinkerApp

tokenchars "Thnk"
tokenid 16410

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource QUIZRESULTSRESOURCE ui-object

resource DOCGROUPRESOURCE object

resource DOCTEMPLATERESOURCE ui-object discard-only read-only shared

resource STRINGSRESOURCE lmem read-only shared data
resource ICON0RESOURCE lmem read-only shared data
resource ICON1RESOURCE lmem read-only shared data
resource ICON2RESOURCE lmem read-only shared data
resource ICON3RESOURCE lmem read-only shared data
resource TINYICONRESOURCE lmem read-only shared data
resource THINKERDOCICONS lmem read-only shared data
resource LOGORESOURCE  data object

library geos
library ui
library ansic

export ThinkerDocumentClass
export AnswerTriggerClass
export ThinkerDocumentControlClass

stack 4000

platform geos20

resource PASSWORDWITHHINTRESOURCE ui-object
resource CHANGEPASSWORDRESOURCE ui-object
resource PWDSTRINGS read-only lmem

usernotes "Copyright 1994-2001 Breadbox Computer Company LLC  All Rights Reserved"

