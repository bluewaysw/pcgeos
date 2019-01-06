##############################################################################
#
# PROJECT:      FontMagick
# FILE:         FontMagi.gp
#
# AUTHOR:       Marcus Gr�ber
#
##############################################################################

name FontMgck.app
longname "FontMagick 1.0"

type   appl, process, single
class  FontMProcessClass
export FontMApplicationClass
appobj FontMApp

stack 2048

platform geos20
exempt gsol
exempt color

tokenchars "FMGK"
tokenid 16431

library	geos
library	ui
library text
library ansic
library color
library gsol
# library ruler

export CharsetClass

resource AppResource                    ui-object
resource Interface                      ui-object
resource FontMagickMonikerResource      lmem read-only shared
resource BREADBOXMONIKERRESOURCE        lmem read-only shared
resource BREADBOXMONIKERRESOURCE2       lmem read-only shared
