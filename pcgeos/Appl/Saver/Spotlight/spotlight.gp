# Parameters for specific screen saver library
# $Id: spotlight.gp,v 1.1 97/04/04 16:45:21 newdeal Exp $
name spotlight.lib
type appl, process, single
longname "Spotlight"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
class SpotlightProcessClass
appobj SpotlightApp
export SpotlightApplicationClass
