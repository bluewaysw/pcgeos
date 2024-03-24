name laserl.app
longname "Laser Letters"
type    appl, process, single
class   LaserLettersProcessClass
appobj  LaserLettersApp
tokenchars "LasL"
tokenid 16431
library geos
library ui
library ansic
resource AppResource ui-object
resource Interface ui-object
resource GameUi ui-object
resource Strings lmem read-only shared
resource LaserLettersArt1 lmem read-only shared
resource IconResource ui-object

platform geos201

usernotes "Copyright 1994 - 2001   Breadbox Computer Company LLC  All Rights Reserved"
