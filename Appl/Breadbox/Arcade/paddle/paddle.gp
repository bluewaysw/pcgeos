name paddle.app
longname "Paddle Challenge"

type    appl, process, single
class   PaddleProcessClass
appobj  PaddleApp

tokenchars "PCha"
tokenid 16431

#platform gpc12
platform geos201

library geos
library ui
library ansic
library color
library game
library sound

exempt color
exempt game
exempt sound

resource AppResource	 	object
resource Interface		 	object
resource AppMonikerResource object
resource QTipsResource	 	object
resource InterfaceOption 	object
resource BallResource		object

export PaddleProcessClass

