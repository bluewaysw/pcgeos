name vacman.app
longname "VacMan"
type    appl, process, single
class   VacManProcessClass
appobj  VacManApp

tokenchars "VACM"
# jfh use Breadbox Mfr ID
tokenid 16431

platform geos201

library geos
library ui
library game
library ansic
library wav
library sound


exempt wav
exempt game
exempt sound


resource QTipsResource ui-object
resource AppResource ui-object
resource Interface ui-object
resource Icon0Resource ui-object lmem shared read-only
#resource SPRITERESOURCE lmem
resource VacUpResource data
resource VacDownResource data
resource VacLeftResource data
resource VacRightResource data
resource CloudResource data
resource BunBagResource data
#resource BOARDRESOURCE lmem read-only shared
resource BoardResource data
resource CurrentBoardResource data
#resource STRINGSRESOURCE lmem read-only shared
resource StringsResource lmem read-only shared
#resource BREADBOXMONIKERRESOURCE ui-object lmem read-only shared
#resource BREADBOXMONIKERRESOURCE2 ui-object lmem read-only shared
#resource OPENINGLOGO1RESOURCE ui-object lmem read-only shared
#resource OPENINGLOGO2RESOURCE ui-object lmem read-only shared

export VacContentClass
export VacApplicationClass



