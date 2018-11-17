# Parameters for specific screen saver library
# $Id: melt.gp,v 1.1 97/04/04 16:46:02 newdeal Exp $
name melt.lib
type appl, process, single
longname "Melt"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
class MeltProcessClass
appobj MeltApp
export MeltApplicationClass
