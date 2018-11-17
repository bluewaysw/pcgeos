# Parameters for specific screen saver library
# $Id: dust.gp,v 1.1 97/04/04 16:48:26 newdeal Exp $
name dust.lib
type appl, process, single
longname "Dust"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
class DustProcessClass
appobj DustApp
export DustApplicationClass
