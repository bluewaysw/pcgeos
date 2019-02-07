name follow.app
longname "Follow Me"
type    appl, process, single
class   FollowProcessClass
appobj  FollowApp
tokenchars "FoMe"
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
resource InterfaceDone object
resource InterfaceStartLevel object
resource InterfaceSpeed object
resource InterfaceReaction object
resource InterfaceSound object
resource StringsResource lmem read-only shared discardable
resource QTipsResource object

export FollowProcessClass
export FollowViewClass
export FollowContentClass

