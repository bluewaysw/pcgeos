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


resource QTIPSRESOURCE ui-object
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource ICON0RESOURCE ui-object lmem shared read-only
#resource SPRITERESOURCE lmem
resource VACUPRESOURCE data
resource VACDOWNRESOURCE data
resource VACLEFTRESOURCE data
resource VACRIGHTRESOURCE data
resource CLOUDRESOURCE data
resource BUNBAGRESOURCE data
#resource BOARDRESOURCE lmem read-only shared
resource BOARDRESOURCE data
resource CURRENTBOARDRESOURCE data
#resource STRINGSRESOURCE lmem read-only shared
resource STRINGSRESOURCE data
#resource BREADBOXMONIKERRESOURCE ui-object lmem read-only shared
#resource BREADBOXMONIKERRESOURCE2 ui-object lmem read-only shared
#resource OPENINGLOGO1RESOURCE ui-object lmem read-only shared
#resource OPENINGLOGO2RESOURCE ui-object lmem read-only shared

export VacContentClass
export VacApplicationClass



