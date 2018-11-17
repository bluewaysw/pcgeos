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
resource APPRESOURCE ui-object
resource INTERFACE ui-object

ifndef PRODUCT_GPC
resource ACTIONBAR1RESOURCE ui-object
resource ACTIONBAR2RESOURCE ui-object
resource ACTIONBAR3RESOURCE ui-object
resource ACTIONBAR4RESOURCE ui-object
resource NAVIGATIONBARRESOURCE ui-object
else
resource MINIMUMTOOLSMONIKERRESOURCE ui-object
resource MESSAGEWINDOWRESOURCE ui-object
resource MINIMUMTOOLSRESOURCE ui-object
resource MESSAGEWINDOWMONIKERRESOURCE ui-object
endif

resource MAINAREARESOURCE ui-object
resource MAINLISTRESOURCE ui-object
resource POSTTEXTRESOURCE ui-object
resource POSTWINDOWRESOURCE ui-object
resource STRINGSRESOURCE lmem read-only shared data
#resource LOGORESOURCE lmem read-only shared data
resource DEBUGWINDOWRESOURCE ui-object
resource DOWNLOADDIALOGRESOURCE ui-object
resource SETTINGSDIALOGRESOURCE ui-object
resource SAVEFILESRESOURCE ui-object
resource ADDNEWSGROUPDIALOGRESOURCE ui-object
resource LOGINDIALOGRESOURCE ui-object

resource NEWMESSAGESDIALOGRESOURCE ui-object

resource MONIKER0RESOURCE lmem read-only shared
resource MONIKER1RESOURCE lmem read-only shared
resource MONIKER2RESOURCE lmem read-only shared
resource MONIKER3RESOURCE lmem read-only shared

ifdef PRODUCT_BBXBETA
resource BETADIALOGRESOURCE ui-object
endif

#resource ABOUTDIALOGRESOURCE ui-object


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

