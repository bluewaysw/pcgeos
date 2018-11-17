##############################################################################
#
#	Copyright (c) NewDeal 1999 -- All Rights Reserved
#
# PROJECT:	GeoSafari
#
# AUTHOR:	Gene Anderson
#
# RCS STAMP:
#	$Id$
#
##############################################################################

name safari2.app

longname "GeoExplorer"

type	appl, process, single

class	SafariProcessClass

appobj	SafariAppObj

tokenchars "GEPL"
tokenid 16431

library	geos
library	ui
library safari
library ansic
library game
library sound
library wav

resource APPRESOURCE ui-object
resource APPICONS data object
resource INTERFACE ui-object
resource OPTIONSUI ui-object
resource STRINGS   lmem shared read-only
resource BACKBITMAPS1   lmem shared read-only
resource BACKBITMAPS2   lmem shared read-only
resource UIBITMAPS lmem shared read-only

export SafGameCardClass
export LogoDisplayClass
export GameTimerClass
export PlayerInputClass
export SafariAppClass
# export SettingsButtonClass jh - don't need
export SafBackgroundClass
