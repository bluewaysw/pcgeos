#
# Geode Parameters for Breadbox CD Player
#
# $Id: 021097

name bbxcd.app

longname "CD Player"

type    appl, process, single

class   BCProcessClass

platform geos20

appobj  BApp

tokenchars "NWCD"
tokenid 16427

library geos
library ui
library sound
library ansic
library cdaudio

exempt ansic
exempt cdaudio
exempt sound

# Muá neu berechnet werden !
heapspace 9720

resource APPRESOURCE           ui-object
resource INTERFACE             ui-object
resource MAXINTERFACE          ui-object
resource ABSRESOURCE           ui-object
resource BALANCERESOURCE       ui-object
resource CDINFORESOURCE        ui-object
resource DBEDITORRESOURCE      ui-object

resource BBXMONIKERRESOURCE    data object read-only
resource PRTURNMONIKERRESOURCE data object read-only
resource MODUSMONIKERRESOURCE  data object read-only
resource APPLMONIKERRESOURCE   data object read-only
resource MINMONIKERRESOURCE    data object read-only
resource MAXMONIKERRESOURCE    data object read-only
resource TURNMONIKERRESOURCE   data object read-only
#resource ABSMONIKERRESOURCE    data object read-only
resource FIRSTAIDRESOURCE      data object read-only
resource TURNGRAPHICRESOURCE   lmem data read-only
resource TEXTSTRINGS data object

# this fake resource fixes the code content of key.goc.
# this is necessary because key.goc contains inline assembler code
# that may not be relocated (system crash imminent).
resource KEY_TEXT              preload fixed code read-only

# usernotes "Komfortabler CD-Player mit Datenbank."
#usernotes "Luxuriant CD-player with database."
usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

export BCApplicationClass
export BCPrimaryClass
export BCTriggerClass

