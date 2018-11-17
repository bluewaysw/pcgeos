#**************************************************************************
#       GEODE-Parameter-File fÅr 3DBooster-Applikation
#       (c) by RABE-Soft 10/96
#**************************************************************************

# Name der Applikation fÅr glue und swat

name geozip.app

# Name fÅr GeoManager

longname "GeoZip"

# spezifiziert den Applikations-typ

type appl, process, single

#  class legt den KlassenName des Applikations-Proze·-Objekts fest. Messages,
#  die an den Appliaktions-Proze· gesendet werden, mÅssen hier behandelt werden.

class GZipProcessClass

# alle anderen Klassen mÅssen mit export bekannt gemacht werden


# legt fest, welches Objekt die Applikation nach "au·en" vertreten soll.
# Dieses Objekt ist gleichzeitig das Top-Level-Objekt im UI-tree

appobj GZipApp
platform geos20

export GZipDisplayClass
export GZipDocumentClass
export GZipDocumentControlClass
export GZipDocumentGroupClass
export OpenNewInfoClass
export ExtractArchiveInfoClass
export NewZipInteractionClass
#export SharewareGlyphClass

#export BargrafViewClass
#export BargrafContentClass
#export BargrafClass

stack 4000

# Token fÅr den GeoManager

tokenchars "GZip"
tokenid    16431

# einzubindende Librarys

library geos
library ui
#library borlandc
library ansic

library minizip
exempt minizip

library dirlist
exempt dirlist

library extui
exempt extui

# Aufteillung der Applikation in Recourcen

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource VIEWRESOURCE ui-object
resource OPENNEWRESOURCE ui-object
resource TEMPLATERESOURCE ui-object
resource MENURESOURCE ui-object

resource DISPLAYUI object shared read-only
resource DOCUMENTUI object
resource APPICONRESOURCE data
#resource DOCICONRESOURCE data
resource GRAPHICSRESOURCE data
resource FSGRAPHICSRESOURCE data
resource FSGRAPHICSRESOURCE1 data
resource TEXTRESOURCE data lmem

incminor

export GZipDisplayGroupClass

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

