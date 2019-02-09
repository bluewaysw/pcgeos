name thinker.app
longname "Thinker Pro"
type    appl, process, single
class   ThinkerProcessClass
appobj  ThinkerApp

tokenchars "Thnk"
tokenid 16410

resource AppResource ui-object
resource Interface ui-object
resource QuizResultsResource ui-object

resource DocGroupResource object

resource DocTemplateResource ui-object discard-only read-only shared

resource StringsResource lmem read-only shared data
resource Icon0Resource lmem read-only shared data
resource Icon1Resource lmem read-only shared data
resource Icon2Resource lmem read-only shared data
resource Icon3Resource lmem read-only shared data
resource TinyIconResource lmem read-only shared data
resource ThinkerDocIcons lmem read-only shared data
resource LOGORESOURCE  data object

library geos
library ui
library ansic

export ThinkerDocumentClass
export AnswerTriggerClass
export ThinkerDocumentControlClass

stack 4000

platform geos20

resource PasswordWithHintResource ui-object
resource ChangePasswordResource ui-object
resource PwdStrings read-only lmem

usernotes "Copyright 1994-2001 Breadbox Computer Company LLC  All Rights Reserved"
