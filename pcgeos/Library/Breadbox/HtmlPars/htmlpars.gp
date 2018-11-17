##############################################################################
#
# PROJECT:      HTMLPars
# FILE:         htmlpars.gp
#
# AUTHOR:       Marcus Gr”ber
#
##############################################################################

name       htmlpars.lib
longname   "Breadbox HTML Parse Library"
tokenchars "HTML"
tokenid    16431

type       library, single

#platform   zoomer

library    geos
library    ansic
library    text

export     PARSEHTMLFILE
export     PARSEPLAINFILE
export     TOOLSPARSEDISKORSTANDARDPATH
export     TOOLSPARSEURL
export     TOOLSMAKEURL
export     TOOLSRESOLVEPATHNAME
export     TOOLSRESOLVERELATIVEURL
export     TOOLSMAKEURLABSOLUTE
export     TOOLSSTRINGSECTIONFINDKEY
export     TOOLSFORMATMESSAGE
export     XSTRNCPY
export     HTMLTextClass
export     TOOLSFINDEXTENSION
export     TOOLSNORMALIZEURL
export     CREATEHTMLFILE

resource   STYLERESOURCE   lmem read-only shared
resource   ENTITYRESOURCE  lmem read-only shared
resource   POINTERRESOURCE lmem read-only shared

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

