name easyarr.lib

longname    "EasyArray Library"
tokenchars  "EALI"
tokenid     17

type    library, single, c-api

stack 2000

library geos
library ui
library ansic

export EASYARRGETVMFILE
export EASYARRINIT
export EASYARRDESTROY
export EASYARRAPPENDENTRY
export EASYARRGETCOUNT
export EASYARRLOCKENTRY
export EASYARRUNLOCKENTRY
