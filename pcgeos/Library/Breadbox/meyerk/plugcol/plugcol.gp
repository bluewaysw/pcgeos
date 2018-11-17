name plugcol.lib

longname    "Plug-In Collection"
tokenchars  "FMTL"
tokenid     0

type    library, single, c-api

#resource FMUI object lmem read-only shared  jfh1
resource FMUI lmem read-only shared
#resource CAUI ui-object read-only  jfh1
resource CAUI ui-object shared
#resource DIALOGUI ui-object read-only  jfh1
resource DIALOGUI ui-object shared

stack 6000

library geos
library ui
library ansic
library text
library easyarr
#library debug

export GETTHOSETOOLS
export CHANGEATTRSENTRY
export TESTIFDIR
export CHANGEATTRFORFILE
export CHANGEATTRS
