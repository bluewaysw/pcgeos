# Parameters for specific screen saver library
# $Id: tiles.gp,v 1.1 97/04/04 16:48:03 newdeal Exp $
name tiles.lib
type appl, process, single
longname "Tiles"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
class TilesProcessClass
appobj TilesApp
export TilesApplicationClass
