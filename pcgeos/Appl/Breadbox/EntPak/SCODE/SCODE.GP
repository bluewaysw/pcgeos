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

resource APPRESOURCE object
resource INTERFACE object
resource WINMONIKERRESOURCE object
resource LOSEMONIKERRESOURCE object
#resource SCOREINTERFACE object
resource INTERFACEOPTIONS object
#resource INTERFACEVIEW object
resource INTERFACEWIN object
resource INTERFACELOSE object
resource STRINGSRESOURCE data
resource QTIPSRESOURCE object

export SecretCodeProcessClass
export SecretCodeViewClass
export SecretCodeContentClass
export SecretCodeTimerClass
export SecretCodeAppClass
export SecretCodePauseInterClass
