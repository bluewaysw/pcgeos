name row4.app
longname "Four in a Row"
type    appl, process, single
class   Row4ProcessClass
appobj  Row4App
tokenchars "FRow"
tokenid 16431

platform gpc12
library geos
library ui
library ansic
library sound

exempt sound

stack 6000
resource AppResource object
resource Interface object
resource Win1MonikerResource object
resource Win2MonikerResource object
resource WinCMonikerResource object
resource TieMonikerResource object
#resource InterfaceAbout object
resource InterfaceWin1 object
resource InterfaceWin2 object
resource InterfaceWinC object
resource InterfaceTie object
#resource StringsResource lmem read-only shared discardable
resource ResourcePictures data
resource QTipsResource object

export Row4ViewClass
export Row4ContentClass

