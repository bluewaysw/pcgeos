name magic.app

longname "Magic Board"

type    appl, process, single

class   MagicProcessClass

appobj  MagicApp

tokenchars "Magi"
tokenid    16431

platform gpc12
library   geos
library   ui
library   ansic
library   math
library   game
library	 sound

exempt math
exempt borlandc
exempt game
exempt sound

resource  APPRESOURCE              ui-object
#resource  DIALOGRESOURCE           ui-object
resource  INTERFACERESOURCE        ui-object
resource  BOARDRESOURCE            ui-object
#resource  HIGHSCOREGLYPHRESOURCE   ui-object
resource  GAMEENDRESOURCE          ui-object
resource  ICONRESOURCE             ui-object
resource STRINGSRESOURCE data object
resource QTIPSRESOURCE ui-object

export    MagicContentClass
export    MagicPieceClass


