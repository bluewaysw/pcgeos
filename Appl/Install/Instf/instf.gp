#**************************************************************************
#       GEODE-Parameter-File f¸r UniInstaller-Applikation
#       (c) by RABE-Soft 7/99 - 05/2023
#**************************************************************************

# Name der Applikation f¸r glue und swat

name install.app

# Name f¸r GeoManager

longname "Universal Installer"
usernotes "English FreeGEOS Version 6.0.1"

# spezifiziert den Applikations-typ

type appl, process, single

#  class legt den KlassenName des Applikations-Proze·-Objekts fest. Messages,
#  die an den Appliaktions-Proze· gesendet werden, mÅssen hier behandelt werden.

class IFProcessClass

# alle anderen Klassen mÅssen mit export bekannt gemacht werden

export IconEditDialogClass
export FileSelectDialogClass
export IFDocumentControlClass

# legt fest, welches Objekt die Applikation nach "au·en" vertreten soll.
# Dieses Objekt ist gleichzeitig das Top-Level-Objekt im UI-tree
appobj IFApp

# make the program downward compatible as possible
platform geos20

# Token for the GeoManager
tokenchars "IstF"
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
resource IconEditResource ui-object
resource DebugResource ui-object
resource MonikerResource lmem read-only shared
resource IconEditDataResource lmem read-only shared
