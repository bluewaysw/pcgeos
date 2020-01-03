#####################################################################
#
#	Test-Application for Watcom RTL functions in AnsiC-Library.
#
#####################################################################

name     wccrtl.app

longname "Watcom RTL Test"

tokenchars "wccr"
tokenid    0

type   appl, process, single

class  WatcomRTLProcessClass

appobj WatcomRTLApp

library	geos
library	ui
library ansic

resource AppResource ui-object
resource Interface   ui-object

