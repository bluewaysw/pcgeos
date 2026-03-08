#
# FirstRun geode definition
#

name firstrun.app
longname "FirstRun"

type appl, process, single

class FirstRunProcessClass
appobj FirstRunApp

tokenchars "FRUN"
tokenid 0

heapspace 3000

library geos
library ui
library ansic

resource AppResource ui-object
resource SeedResource data read-only shared
