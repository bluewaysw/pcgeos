##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	ResEdit
# FILE:		localize.gp
#
# AUTHOR:	Cassie Hartzog, Sep 28, 1992
#
#
#	$Id: localize.gp,v 1.1 97/04/04 17:13:57 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name resedit.app
#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname "ResEdit"
#
# Specify geode type: is an application, will have its own process (thread),
# and is multi-launchable.
#
type	appl, process
stack	3000
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the ResEditProcessClass, which is defined in
# resEdit.asm.
#
class	ResEditProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application.
#
appobj	ResEditApp
#
# Token: this four-letter name is used by GeoManager to locate the icon
# for this application in the database.
#
tokenchars "RSED"
tokenid 0
#
# Import library routine definitions
#
library	geos
library	ui
library	text
library	spool
#
# Define resources other than standard discardable code
#
# Icons
resource AppLCMonikerResource ui-object read-only discardable
resource AppSCMonikerResource ui-object read-only discardable
resource AppLMMonikerResource ui-object read-only discardable
resource AppSMMonikerResource ui-object read-only discardable
resource AppLCGAMonikerResource ui-object read-only discardable
resource AppSCGAMonikerResource ui-object read-only discardable

# General UI -- UI thread
resource AppResource 	 ui-object
resource PrimaryUI 	 ui-object
resource FileMenuUI 	 ui-object
resource ProjectMenuUI 	 ui-object
resource DisplayTemplate ui-object read-only shared
resource PrintUI 	 ui-object

# General data -- application thread
resource AppDocUI 	 object 
resource ContentTemplate object read-only shared
resource MiscObjectUI 	 object
resource StringsUI	 lmem read-only shared
resource ErrorStrings	 lmem read-only shared
resource DummyResource	 lmem discardable data
resource BitmapTemplate	 object read-only shared
ifndef	DO_DBCS
# If not dbcs, import/export will work. (responder feature)
resource ResEditKeywordResource  lmem read-only shared
resource ImportResource  lmem
endif

#
# Export classes defined by the application
#
export  ResEditApplicationClass
export  ResEditContentClass
export	ResEditGlyphClass
export  ResEditDocumentClass
export  ResEditTextClass
export  ResEditValueClass
export  ResEditMnemonicTextClass
export  ResEditDisplayClass
export	ResEditGenDocumentControlClass
ifndef	DO_DBCS
export	ResEditFileSelectorClass
export	ResEditImpTextClass
endif
export	ResEditViewClass
