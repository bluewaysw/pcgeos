name blkbox.app
longname "The Black Box"
type    appl, process, single
class   BlackBoxProcessClass
appobj  BlackBoxApp
tokenchars "BBox"
tokenid 16431


# Libraries
platform gpc12

library geos
library ui
library ansic
library game
library sound

exempt game
exempt sound

# Resources

resource APPRESOURCE object
resource INTERFACE object
resource WINMONIKERRESOURCE object
resource LOSEMONIKERRESOURCE object
resource BADGUESSMONIKERRESOURCE object
#resource INTERFACEHIGHSCORES object
resource INTERFACEBADGUESS object
resource INTERFACELOSE object
resource INTERFACEWIN object
#resource INTERFACEPLACE object
resource INTERFACEOPTIONS object
#resource INTERFACEVIEW object
resource STRINGSRESOURCE data lmem read-only shared discardable
resource QTIPSRESOURCE object

# exports

export BlackBoxProcessClass
export BlackBoxViewClass
export BlackBoxContentClass
export BlackBoxTimerClass
export BlackBoxPrimaryClass
export BlackBoxPauseInterClass
export BlackBoxAppClass
