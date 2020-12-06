# Testprogramm for functions from the maths library which 
# are affected by the changes for 64bit long double support.
name     mathtest.app

longname "MathTest"

tokenchars "TEST"
tokenid    0

type   appl, process, single

class  MathtestProcessClass

appobj		MathtestApp

library		geos
library		ui
library     ansic
library     math

resource AppResource ui-object
resource Interface   ui-object

