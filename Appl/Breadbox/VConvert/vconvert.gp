##############################################################################
#
# PROJECT:      VConvert
# FILE:         VConvert.gp
#
# AUTHOR:       Marcus Groeber
#
##############################################################################

name vconvert.app
longname "V-Convert"

type   appl, process, single
class  VConvProcessClass
export VConvApplicationClass
appobj VConvApp

#platform geos20
#exempt meta

tokenchars "VCNV"
tokenid 16424

library	geos
library	ui
library ansic
library text
library math
library meta
library grobj
# library ruler

stack 4096

resource AppResource ui-object
resource Interface ui-object
resource VConvMonikerResource lmem read-only shared
resource VConvTitleResource lmem read-only shared

