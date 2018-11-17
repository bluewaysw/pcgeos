# Parameters for specific screen saver library
# $Id: sand.gp,v 1.1 97/04/04 16:47:04 newdeal Exp $
name sand.lib
type appl, process, single
longname "Sand"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
class SandProcessClass
appobj SandApp
export SandApplicationClass
