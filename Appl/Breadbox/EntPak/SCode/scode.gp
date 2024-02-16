name scode.app
longname "Secret Code"
type    appl, process, single
class   SecretCodeProcessClass
appobj  SecretCodeApp
tokenchars "SCod"
tokenid 16431

platform gpc12
library geos
library ui
library ansic
library game
library sound

exempt game
exempt sound

resource AppResource object
resource Interface object
resource WinMonikerResource object
resource LoseMonikerResource object
#resource ScoreInterface object
resource InterfaceOptions object
#resource InterfaceView object
resource InterfaceWin object
resource InterfaceLose object
resource StringsResource lmem read-only shared
resource QTipsResource object
resource ResourcePictures lmem read-only shared

export SecretCodeProcessClass
export SecretCodeViewClass
export SecretCodeContentClass
export SecretCodeTimerClass
export SecretCodeAppClass
export SecretCodePauseInterClass
