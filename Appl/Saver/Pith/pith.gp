# Parameters for specific screen saver library
# $Id: pith.gp,v 1.1 97/04/04 16:48:45 newdeal Exp $
name pith.lib
type appl, process, single
longname "Pith & Moan"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
library text
class PithProcessClass
appobj PithApp
export PithApplicationClass
