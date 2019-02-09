#**************************************************************************
#       GEODE-Parameter-File f�r 3DBooster-Applikation
#       (c) by RABE-Soft 10/96
#**************************************************************************

# Name der Applikation f�r glue und swat

name geozip.app

# Name f�r GeoManager

longname "GeoZip"

# spezifiziert den Applikations-typ

type appl, process, single

#  class legt den KlassenName des Applikations-Proze�-Objekts fest. Messages,
#  die an den Appliaktions-Proze� gesendet werden, m�ssen hier behandelt werden.

class GZipProcessClass

# alle anderen Klassen m�ssen mit export bekannt gemacht werden


# legt fest, welches Objekt die Applikation nach "au�en" vertreten soll.
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

# Token f�r den GeoManager

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

resource AppResource ui-object
resource Interface ui-object
resource ViewResource ui-object
resource OpenNewResource ui-object
resource TemplateResource ui-object
resource MenuResource ui-object

resource DisplayUI object shared read-only
resource DocumentUI object
resource AppIconResource data
#resource DocIconResource data
resource GraphicsResource data
resource FSGraphicsResource data
resource FSGraphicsResource1 data
resource TextResource data lmem

incminor

export GZipDisplayGroupClass

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

