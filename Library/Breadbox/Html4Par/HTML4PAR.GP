##############################################################################
#
# PROJECT:      HTMLPars
# FILE:         htmlpars.gp
#
# AUTHOR:       Marcus Gr”ber
#
##############################################################################

name       html4par.lib
longname   "Breadbox HTML 4 Parse Library"
tokenchars "HTML"
tokenid    16431

type       library, single

library    geos
library    ui
library    ansic
library    extgraph

# Uncomment the following when building a "regular" Geos version:
library text

# Uncomment the following when building a Yago version:
#library tex2


# Uncomment the following when building a version with strong heap checking:
#library    hwlib


export     PARSEHTMLFILE
export     PARSEPLAINFILE
export     PARSEANYFILE
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

export     NAMEPOOLCREATE
export     NAMEPOOLFREE
export     NAMEPOOLTOKENIZELEN
export     NAMEPOOLUSETOKEN
export     NAMEPOOLRELEASETOKEN
export     NAMEPOOLTESTEQUAL
export     NAMEPOOLCOPY
export     NAMEPOOLDESTROYIFDYNAMIC
export     NAMEPOOLVMSAVE
export     NAMEPOOLTOKENIZEFROMVM

export     NAMEASSOCCREATE
export     NAMEASSOCFREE
export     NAMEASSOCASSOCIATE
export     NAMEASSOCFINDASSOCIATION

export     VMLOCKCHAINIFIEDLMEMBLOCK
export     VMUNLOCKCHAINIFIEDLMEMBLOCK

export     DEBUGDIALOGPRINTF

export     FormElementSelectListClass
export     PROGRESSDIALOGCREATE
export     ProgressDialogClass
export     ProgressIndicatorClass

export     CopyArrayWithTokens
export     FreeArrayNameTokens

export     SYSNOTIFYWITHDATA
export     GETNTHFROMLIST
export     NAMEPOOLTESTEQUALI
export     NAMEPOOLISTOKENVALID

export     NAMEPOOLTOKENIZEFROMPOOL

export     NAMEPOOLCONCATSTR

export     LMEMDUP

export	   NAMEPOOLVMLOAD

resource   STYLERESOURCE   lmem read-only shared
resource   ENTITYRESOURCE  lmem read-only shared
resource   COLORRESOURCE   lmem read-only shared
resource   POINTERRESOURCE lmem read-only shared
resource   FORMBUTTONRESOURCE lmem read-only shared
resource   ASM_TEXT fixed

# only needed if IN_PLACE_TEXT_ENTRY in options.goh
resource   FORMELEMENTTEXTENTRYRESOURCE object

export     NAMEPOOLFIND

# only needed if IN_PLACE_TEXT_ENTRY in options.goh
export     InPlaceTextEntryClass

# only needed if IN_PLACE_SELECT_LIST in options.goh
resource   FORMELEMENTSELECTLISTPOPUPRESOURCE ui-object
export     FormElementSelectPopupListClass

# FormString routines
export     FormStringCreate
export     FormStringAppend
export     FormStringConvertAndAppend
export     FormStringDerefData

# only needed if IN_PLACE_TEXT_ENTRY in options.goh
resource   FORMELEMENTTEXTAREAENTRYRESOURCE object
export     InPlaceTextAreaEntryClass

export	   FreeHTMLTransferItem	

export	   NAMEPOOLVMUNLOAD

export     NAMEPOOLSTRLENGTH

incminor

export     NAMEPOOLINITIALIZEDYNAMIC
export     NAMEPOOLISDYNAMIC
export     NAMEPOOLRESIZEDYNAMIC

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

export	   PARSEABORT

incminor

export     HTMLTRANSLATECOLOR

incminor

export     HTMLTRANSLATECHARNUM
export     HTMLTRANSLATECHAR

export     NAMEPOOLTOKENIZELENDOS
