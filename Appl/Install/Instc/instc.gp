#**************************************************************************
#       GEODE-Parameter-File for Install Creator-Applikation
#       (c) by RABE-Soft 10/96 - 05/2023
#**************************************************************************

# Name der Applikation fÅr glue und swat

name ICreat.app

# Name for GeoManager

longname "Install Creator"
usernotes "English Version 1.4.0"
# spezifiziert den Applikations-typ

type appl, process, single

#  class legt den KlassenName des Applikations-Proze·-Objekts fest. Messages,
#  die an den Appliaktions-Proze· gesendet werden, mÅssen hier behandelt werden.

class ICProcessClass

# alle anderen Klassen mÅssen mit export bekannt gemacht werden

export ICOptionsDialogClass
export FileSelectDialogClass
export IconEditDialogClass
export InifEditDialogClass
export SelectDirOrFileDialogClass


# legt fest, welches Objekt die Applikation nach "auﬂen" vertreten soll.
# Dieses Objekt ist gleichzeitig das Top-Level-Objekt im UI-tree

appobj ICApp

# make the program compatible width BreadBox Ensemble 4.1.3
platform geos21

# Token for den GeoManager

tokenchars "ICre"
tokenid    16480

# einzubindende Librarys

library geos
library ui
library ansic


# Aufteillung der Applikation in Recourcen

resource AppResource ui-object
resource Interface ui-object
resource DocumentUI object
resource DialogResource ui-object
resource MonikerResource lmem read-only shared
resource DataResource lmem read-only shared
resource IconEditResource ui-object
resource InifUIResource lmem read-only shared
resource InifDialogResource ui-object
resource FToolDataResource lmem read-only shared
resource FToolDialogResource ui-object

