name            sstor.lib
longname        "Breadbox Docfile (SS) Library"

type            library, single

tokenchars      "BBSS"
tokenid         16431

library         geos
library         ansic

export          StgOpenDocfile
export          StgCloseDocfile
export          StgStorageOpen
export          StgStorageClose
export          StgStreamOpen
export          StgStreamClone
export          StgStreamRead
export          StgStreamSeek
export          StgStreamPos
export          StgStreamGetLastError
export          StgStreamClose

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

