##############################################################################
#
# PROJECT:      Build a new (!) word list for Word Matcher
# FILE:         wlistgen.gp
#               Copyright (c) by RABE-Soft 06/2024
#
# AUTHOR:       Rainer Bettsteller
#
##############################################################################


# *************** Informationen for Glue *************** #

name        wlgen.app
type        appl, process, single
platform    geos201
class       WListProcessClass
appobj      WListApp

longname    "Word List Creator"
tokenchars  "EDU2"
tokenid     5


# *************** Libraries *************** #

library	geos
library	ansic
library	ui
library wmlib

exempt wmlib

# *************** Resourcen *************** #
# Bsp: resource DATARESOURCE lmem read-only shared data

resource	AppResource ui-object
resource	Interface ui-object
resource	MenuResource ui-object
resource	DataResource lmem read-only shared


# *************** Exportierte Klassen und Routinen *************** #
# Bsp: export SOMEROUTINE
export 	StopTriggerClass



# *********** end of file wlistgen.gp *******************


