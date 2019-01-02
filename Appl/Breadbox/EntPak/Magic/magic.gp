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

resource  AppResource              ui-object
#resource  DialogResource          ui-object
resource  InterfaceResource        ui-object
resource  BoardResource            ui-object
#resource  HighScoreGlyphResource  ui-object
resource  GameEndResource          ui-object
resource  IconResource             ui-object
resource StringsResource data object
resource QTipsResource ui-object

export    MagicContentClass
export    MagicPieceClass


