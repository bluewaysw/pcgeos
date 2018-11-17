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

resource APPRESOURCE	 	object
resource INTERFACE		 	object
resource APPMONIKERRESOURCE object
resource QTIPSRESOURCE	 	object
resource INTERFACEOPTION 	object
resource BALLRESOURCE		object

export PaddleProcessClass

