name extui.lib
longname "Extended UI Library"

tokenchars "ExUI"
tokenid    16431

type library, single

library geos
library ui
library ansic

resource BitmapResource data read-only shared

export ExtUIStatusBarClass

incminor

export ExtUIHiddenButtonClass

incminor

export ExtUITableClass
export ExtUITreeClass
export ExtUITitledMonikerClass

incminor

export EXTUIUTILSDRAWTEXTLIMITED

