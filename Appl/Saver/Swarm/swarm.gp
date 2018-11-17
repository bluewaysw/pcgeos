# Parameters for specific screen saver library
# $Id: swarm.gp,v 1.1 97/04/04 16:47:31 newdeal Exp $
name swarm.lib
type appl, process, single
longname "Swarm"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
class SwarmProcessClass

resource SwarmClassStructures fixed read-only shared

appobj SwarmApp
export SwarmApplicationClass
