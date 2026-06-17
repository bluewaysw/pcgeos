name picalbum.app

longname "Photo Album"

type appl, process, single

tokenchars "PicA"
tokenid 0

appobj PAApp

class PAProcessClass

stack 8000

platform geos201

library	geos
library ui
library spool
library ansic
library extgraph
library photopc
exempt extgraph
exempt photopc

resource AppResource	            ui-object
resource Interface	                ui-object
resource AlbumScreenResource        ui-object
#resource THUMBNAILSCREENRESOURCE    ui-object
resource ViewScreenResource         ui-object
resource DialogResource				ui-object
resource PrintSizeOptionsResource	ui-object
resource CameraProgressResource		ui-object
#resource DOCUMENTGROUPRESOURCE		object
#resource THUMBNAILVIEWRESOURCE		object
resource AlbumViewResource			object
resource GetPicturesViewResource	object
resource CopyProgressResource           ui-object

#export PAButtonItemClass
#export PAColorInteractionClass
export PAThumbnailListClass
#export PADocumentControlClass
export PASlideShowDialogClass
export PAVerticalDynListClass
export PAPathPopupClass
export PADrivePopupClass
export PACameraProgressClass
