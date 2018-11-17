# Parameters for specific screen saver library
# $Id: flame.gp,v 1.1 97/04/04 16:49:13 newdeal Exp $
name flame.lib
type appl, process, single
longname "Flame Fractal"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
class FlameProcessClass
appobj FlameApp
export FlameApplicationClass
