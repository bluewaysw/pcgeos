name maze.app
longname "Maze Runner"
type    appl, process, single
class   MazeProcessClass
appobj  MazeApp
tokenchars "MRun"
tokenid 16431

platform gpc12
library geos
library ui
library ansic
library color
library game
library sound

exempt color
exempt game
exempt sound

resource APPRESOURCE object
resource INTERFACE object
#resource SAVEDSTATERESOURCE object
resource MOUSE_PICTURE object
resource INTERFACEMOVEBOX object
#resource INTERFACEABOUT object
#resource STRINGSRESOURCE lmem read-only discardable shared
resource QTIPSRESOURCE object

export MazeProcessClass
export MazeViewClass
export MazeContentClass
export MazeTimerClass
export MazeAppClass
export MazePauseInterClass
