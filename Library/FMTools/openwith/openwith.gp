name openwith.lib

longname    "OpenWith"
tokenchars  "FMTL"
tokenid     0

type    library, single, c-api

#resource FMUI object lmem read-only shared  jfh1
resource FMUI lmem read-only shared
#resource CAUI ui-object read-only  jfh1
resource CAUI ui-object shared
#resource DIALOGUI ui-object read-only  jfh1
#resource DIALOGUI ui-object shared

#stack 6000

library geos
library ui
library ansic

export GETTHOSETOOLS
export OPENWITHENTRYPOINT

export OpenWithFileSelectorClass