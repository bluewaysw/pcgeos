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

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource KEYBOARDRESOURCE ui-object
resource RESULTSRESOURCE ui-object
resource TTSTRINGS lmem read-only shared
resource ICONRESOURCE lmem read-only shared
resource WELCOMEDIALOGRESOURCE ui-object
resource RESULTSDIALOGRESOURCE ui-object
resource OPTIONSMENURESOURCE ui-object
resource ASKPASSWORDRESOURCE ui-object
resource MAININTERACTIONRESOURCE ui-object
resource EDITPREFSRESOURCE ui-object
resource LOGORESOURCE  data object

export Step1EntryTextClass
export Step2EntryTextClass
export Step3EntryTextClass
export KeyVisClass
export ResultsVisClass
export TTExTextClass
export ExerciseEditorClass

stack 4000

