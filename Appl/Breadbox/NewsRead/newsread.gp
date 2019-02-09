# General header information
name newsread.app

longname "NewsReader"

type    appl, process, single

class   NewsProcessClass

appobj  NewsApp

tokenchars "NEWS"
# should be Breadbox number, not until we get real icon
tokenid 16431

#platform N9110V10

stack 5000

# Resources
resource AppResource ui-object
resource Interface ui-object

ifndef PRODUCT_GPC
resource ActionBar1Resource ui-object
resource ActionBar2Resource ui-object
resource ActionBar3Resource ui-object
resource ActionBar4Resource ui-object
resource NavigationBarResource ui-object
else
resource MinimumToolsMonikerResource ui-object
resource MessageWindowResource ui-object
resource MinimumToolsResource ui-object
resource MessageWindowMonikerResource ui-object
endif

resource MainAreaResource ui-object
resource MainListResource ui-object
resource PostTextResource ui-object
resource PostWindowResource ui-object
resource StringsResource lmem read-only shared data
#resource LOGORESOURCE lmem read-only shared data
resource DebugWindowResource ui-object
resource DownloadDialogResource ui-object
resource SettingsDialogResource ui-object
resource SaveFilesResource ui-object
resource AddNewsgroupDialogResource ui-object
resource LoginDialogResource ui-object

resource NewMessagesDialogResource ui-object

resource Moniker0Resource lmem read-only shared
resource Moniker1Resource lmem read-only shared
resource Moniker2Resource lmem read-only shared
resource Moniker3Resource lmem read-only shared

ifdef PRODUCT_BBXBETA
resource BETADIALOGRESOURCE ui-object
endif

#resource AboutDialogResource ui-object


# Required libraries
library geos
library ui
library socket
library ansic
library text
library spool
library spell
library inetmsg
library extui
library parentc
ifdef PRODUCT_NDO2000
else
library idialc
endif

# Exported classes (required by system)
export NewsContentClass
export NewsTextClass
export NewsHeaderTextClass
export StatusDialogClass
export GenTextChangedClass
export SettingsDialogClass
export AddNewsgroupDialogClass
export NewsGroupsClass
export ResizeDynamicListClass

export TitledMonikerClass
export GlobeAnimClass
export HiddenButtonClass
export NewsApplicationClass
export ShowToolbarClass

export NewsComposerWindowClass
export NewsReadWindowClass

export PopupHackClass 

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

