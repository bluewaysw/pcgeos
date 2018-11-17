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

resource APPRESOURCE object
resource INTERFACE object
resource LOSEMONIKERRESOURCE object
#resource INTERFACESCORES object
resource INTERFACEDONE object
resource INTERFACESTARTLEVEL object
resource INTERFACESPEED object
resource INTERFACEREACTION object
resource INTERFACESOUND object
resource STRINGSRESOURCE lmem read-only shared discardable
resource QTIPSRESOURCE object

export FollowProcessClass
export FollowViewClass
export FollowContentClass
#export FollowPauseInterClass
#export FollowAppClass

