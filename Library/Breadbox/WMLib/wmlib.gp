name wmlib.lib
longname "Breadbox Word Matcher Library"
type    library, single, c-api
tokenchars "WMLb"
tokenid 16431
library geos
library ansic
library compress
entry WORDMATCHERCENTRY
export WMADDWORD
export WMDELETEWORD
export WMRENAMEWORD
export WMFINDWORD

incminor

export WMCREATENEWDB
export WMADDWORDTONEWDBUNCHECKED
export WMFINISHNEWDB

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

