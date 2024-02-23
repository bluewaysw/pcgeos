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

resource AppResource object
resource Interface object
resource WinMonikerResource object
resource LoseMonikerResource object
resource BadGuessMonikerResource object
#resource InterfaceHighscores object
resource InterfaceBadGuess object
resource InterfaceLose object
resource InterfaceWin object
#resource InterfacePlace object
resource InterfaceOptions object
#resource InterfaceView object
resource StringsResource data lmem read-only shared discardable
resource QTipsResource object
resource ResourcePictures lmem read-only shared discardable

# exports

export BlackBoxProcessClass
export BlackBoxViewClass
export BlackBoxContentClass
export BlackBoxTimerClass
export BlackBoxPrimaryClass
export BlackBoxPauseInterClass
export BlackBoxAppClass
