##############################################################################
#
# PROJECT:      gpcbrow
# FILE:         WebMagi2.gp
#
# AUTHOR:       Marcus Gr”ber and Lysle Shields
#
##############################################################################

ifdef PRODUCT_NDO2000
name browser.app
longname   "Skipper"

else
name bbxbrow.app
#name       webmagi2.app
#name       skipper.app

#Use this name for GlobeHopper release
#longname   "Web Browser"
#longname   "Skipper Pro"
#longname   "Web Magick 2"
#longname   "Global Internet"
longname   "WebMagick 3.0"
endif

type       appl, process, single
class      HTMLVProcessClass
export     HTMLVApplicationClass
appobj     HTMLVApp

#tokenchars "GlbI"
#tokenchars "WMK2"
tokenchars "WMK3"
#tokenchars "Skip"
tokenid    16431

heapspace  64k

stack      8000

library    geos
library    ui
library    ansic
library    text
library    spool
library    html4par
library    ibms
library    netutils
library    cookies

ifdef JAVASCRIPT_SUPPORT
  library    js
endif

# Uncomment the following when building a version with strong heap checking:
#library    hwlib

#library hlfind

#library     bboxlog

# Only needed for COMPILE_OPTION_PARENTAL_CONTROL
library	   parentc

# Only needed for COMPILE_OPTION_IDIAL_CONTROL
library	   idialc

# Only needed for EMBED_SUPPORT
library	   wav

# Only needed for EMAIL_ACCT_CMD
library    mailhub

# For OpenConnection
library    socket

resource   URLFETCH_TEXT        code fixed

resource   APPRESOURCE          ui-object
resource   INTERFACE            ui-object
resource   STATUSRESOURCE       ui-object
resource   TOOLBARRESOURCE      ui-object
resource   SEARCHRESOURCE       ui-object
resource   DOWNLOADDIALOGRESOURCE ui-object
resource   BBOXLOGORESOURCE     ui-object
resource   FILERESOURCE         ui-object
resource   EDITRESOURCE         ui-object
resource   VIEWRESOURCE         ui-object
resource   NAVIGATERESOURCE     ui-object
resource   OPTIONSRESOURCE      ui-object
resource   WINDOWRESOURCE       ui-object

resource   UIRESOURCE           ui-object

resource   FRAMERESOURCE        object
resource   TEXTRESOURCE         object
resource   DOCGROUPRESOURCE     object

resource   HTMLRESOURCE         lmem read-only shared

ifdef COMPILE_OPTION_BOOKMARKS
resource   BOOKMARKUIRESOURCE   ui-object
export     BookmarksDialogClass
endif

ifdef COMPILE_OPTION_FAVORITES
resource   FAVORITEUIRESOURCE               ui-object
resource   FAVORITECREATERESOURCE           ui-object
resource   FAVORITEUILISTDIALOGRESOURCE     ui-object
resource   FAVORITEUIORGANIZERESOURCE       ui-object
resource   FAVORITECREATEGROUPRESOURCE      ui-object
export     FavoritesDialogClass
export     FavoriteCreateDialogClass
export     FavoriteCreateGroupDialogClass
endif

resource   EXPIREDIALOGRESOURCE ui-object
resource   LOCALUIRESOURCE      ui-object
resource   HTMLMENURESOURCE     ui-object

resource   TOPICONS1RESOURCE    ui-object
resource   TOPICONS2RESOURCE    ui-object
resource   TOPICONS3RESOURCE    ui-object
resource   TOPICONS4RESOURCE    lmem read-only shared
resource   ICONBARRESOURCE      ui-object

resource   SIMPLETOOLBARRESOURCE ui-object

ifdef GLOBAL_INTERNET_BUILD
resource   HELPUIRESOURCE       ui-object
resource   HELPFRAMERESOURCE  object
endif

export     URLDocumentControlClass
export     URLDocumentClass
export     URLFrameClass
export     URLTextClass
export     URLFetchEngineClass
export     ImportThreadEngineClass
export     ExpireDialogClass
export     StatusTextClass
export     URLEntryClass
## ifndef GLOBAL_INTERNET_BUILD
## not needed for COMPILE_OPTION_TOGGLE_BARS
export     GlobeAnimClass
## endif
export     WMViewControlClass
export     WMSearchReplaceControlClass

ifdef COMPILE_OPTION_FAVORITES
resource   FAVORITEMANAGERRESOURCE      object
export     FavoriteManagerClass
resource   FAVORITESSTRINGS             lmem read-only shared
endif

#
#these two only needed for COMPILE_OPTION_PARENTAL_CONTROL
#
resource   PCRESOURCE		ui-object
resource   PCROOTRESOURCE	object

resource   VIEWGROUPTEMPLATERESOURCE    ui-object
resource   VIEWTEMPLATERESOURCE         ui-object
resource   FRAMETEMPLATERESOURCE        object

resource   CACHECLEANUPDIALOGRESOURCE   ui-object
# only needed for COMPILE_OPTION_DOWNLOAD_PROGRESS_DIALOG
resource   DOWNLOADPROGRESSDIALOGRESOURCE ui-object

export     URLDocumentGroupClass
export	   FastStatusClass

ifdef JAVASCRIPT_SUPPORT
resource   CONTINUESEGMENT              code fixed
resource   JSUIRESOURCE                 ui-object
endif

ifdef COMPILE_OPTION_PROFILING_ON
library profpnt
endif

ifdef JAVASCRIPT_SUPPORT
resource   WINDOWOPENUIRESOURCE       ui-object
resource   WINDOWOPENFRAMERESOURCE    object
export     WindowOpenInteractionClass
endif

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

