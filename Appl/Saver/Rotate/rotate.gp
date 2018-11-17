# Parameters for specific screen saver library
# $Id: rotate.gp,v 1.1 97/04/04 16:48:58 newdeal Exp $
name rotate.lib
type appl, process, single
longname "Rotate"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
class RotateProcessClass
appobj RotateApp
export RotateApplicationClass
