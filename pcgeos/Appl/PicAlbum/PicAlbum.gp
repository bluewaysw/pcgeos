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

resource APPRESOURCE	            ui-object
resource INTERFACE	                ui-object
resource ALBUMSCREENRESOURCE        ui-object
#resource THUMBNAILSCREENRESOURCE    ui-object
resource VIEWSCREENRESOURCE         ui-object
resource DIALOGRESOURCE				ui-object
resource PRINTSIZEOPTIONSRESOURCE	ui-object
resource CAMERAPROGRESSRESOURCE		ui-object
#resource DOCUMENTGROUPRESOURCE		object
#resource THUMBNAILVIEWRESOURCE		object
resource ALBUMVIEWRESOURCE			object
resource GETPICTURESVIEWRESOURCE	object
resource COPYPROGRESSRESOURCE           ui-object

#export PAButtonItemClass
#export PAColorInteractionClass
export PAThumbnailListClass
#export PADocumentControlClass
export PASlideShowDialogClass
export PAVerticalDynListClass
export PAPathPopupClass
export PADrivePopupClass
export PACameraProgressClass
