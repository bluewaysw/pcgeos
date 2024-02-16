name ttype.gp

longname "Typing Tutor"

type appl, process, single

class TypeProcessClass

appobj TypeApp

platform geos20

tokenchars "Type"
tokenid 3740

library geos
library ui
library text
library ansic
library treplib
exempt treplib

resource AppResource ui-object
resource Interface ui-object
resource KeyboardResource ui-object
resource ResultsResource ui-object
resource TTStrings lmem read-only shared
resource IconResource lmem read-only shared
resource WelcomeDialogResource ui-object
resource ResultsDialogResource ui-object
resource OptionsMenuResource ui-object
resource AskPasswordResource ui-object
resource MainInteractionResource ui-object
resource EditPrefsResource ui-object
resource LOGORESOURCE  data object
resource TabAndStyleResource lmem read-only shared

export Step1EntryTextClass
export Step2EntryTextClass
export Step3EntryTextClass
export KeyVisClass
export ResultsVisClass
export TTExTextClass
export ExerciseEditorClass

stack 4000

