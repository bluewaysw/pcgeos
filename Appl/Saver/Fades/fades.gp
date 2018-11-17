# Parameters for specific screen saver library
# $Id: fades.gp,v 1.1 97/04/04 16:44:54 newdeal Exp $
name fades.lib
type appl, process, single
longname "Fades & Wipes"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
class FadesProcessClass
appobj FadesApp
export FadesApplicationClass
