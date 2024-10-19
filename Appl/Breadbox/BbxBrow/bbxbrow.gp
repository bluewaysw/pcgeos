##############################################################################
#
# PROJECT:      gpcbrow
# FILE:         WebMagi2.gp
#
# AUTHOR:       Marcus Gr�ber and Lysle Shields
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
#longname   "WebMagick 3.0"
longname   "WebMagick"
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

resource   AppResource          ui-object
resource   Interface            ui-object
resource   StatusResource       ui-object
resource   ToolbarResource      ui-object
resource   SearchResource       ui-object
resource   DownloadDialogResource ui-object
resource   BboxLogoResource     ui-object
resource   FileResource         ui-object
resource   EditResource         ui-object
resource   ViewResource         ui-object
resource   NavigateResource     ui-object
resource   OptionsResource      ui-object
resource   WindowResource       ui-object

resource   UIResource           ui-object

resource   FrameResource        object
resource   TextResource         object
resource   DocGroupResource     object

resource   HTMLResource         lmem read-only shared

ifdef COMPILE_OPTION_BOOKMARKS
resource   BookmarkUIResource   ui-object
export     BookmarksDialogClass
endif

ifdef COMPILE_OPTION_FAVORITES
resource   FavoriteUIResource               ui-object
resource   FavoriteCreateResource           ui-object
resource   FavoriteUIListDialogResource     ui-object
resource   FavoriteUIOrganizeResource       ui-object
resource   FavoriteCreateGroupResource      ui-object
export     FavoritesDialogClass
export     FavoriteCreateDialogClass
export     FavoriteCreateGroupDialogClass
endif

resource   ExpireDialogResource ui-object
resource   LocalUIResource      ui-object
resource   HTMLMenuResource     ui-object

resource   TopIcons1Resource    ui-object
resource   TopIcons2Resource    ui-object
resource   TopIcons3Resource    ui-object
resource   TopIcons4Resource    lmem read-only shared
resource   IconBarResource      ui-object

resource   SimpleToolbarResource ui-object

ifdef GLOBAL_INTERNET_BUILD
resource   HelpUIResource       ui-object
resource   HelpFrameResource  object
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
#export     GlobeAnimClass
## endif
export     WMViewControlClass
export     WMSearchReplaceControlClass

ifdef COMPILE_OPTION_FAVORITES
resource   FavoriteManagerResource      object
export     FavoriteManagerClass
resource   FavoritesStrings             lmem read-only shared
endif

#
#these two only needed for COMPILE_OPTION_PARENTAL_CONTROL
#
resource   PCResource		ui-object
resource   PCRootResource	object

resource   ViewGroupTemplateResource    ui-object
resource   ViewTemplateResource         ui-object
resource   FrameTemplateResource        object

resource   CacheCleanupDialogResource   ui-object
# only needed for COMPILE_OPTION_DOWNLOAD_PROGRESS_DIALOG
resource   DownloadProgressDialogResource ui-object

export     URLDocumentGroupClass
export	   FastStatusClass

ifdef JAVASCRIPT_SUPPORT
resource   ContinueSegment              code fixed
resource   JSUIResource                 ui-object
endif

ifdef COMPILE_OPTION_PROFILING_ON
library profpnt
endif

ifdef JAVASCRIPT_SUPPORT
resource   WindowOpenUIResource       ui-object
resource   WindowOpenFrameResource    object
export     WindowOpenInteractionClass
endif

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"
