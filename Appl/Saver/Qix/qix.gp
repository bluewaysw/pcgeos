# Parameters for specific screen saver library
# $Id: qix.gp,v 1.1 97/04/04 16:46:56 newdeal Exp $

name qix.lib

type appl, process, single

longname "Qix"

tokenchars "SSAV"

tokenid 0

library saver
library ui
library geos

class QixProcessClass

appobj QixApp

heapspace 1000

export QixApplicationClass
