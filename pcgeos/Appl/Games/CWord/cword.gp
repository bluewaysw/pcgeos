##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Crossword
# FILE:		cword.gp
#
# AUTHOR:	Peter Trinh, May  3, 1994
#
#
# 
#
#	$Id: cword.gp,v 1.2 98/06/19 19:23:20 gene Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name cword.app

#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Crossword"

#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single



#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the ConnectProcessClass, which is defined
# in con.asm.
#
class	CwordProcessClass

#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See con.ui.
#
appobj	CwordApp

#
# Token: this four-letter name is used by geoManager to locate the icon for 
# this application in the database.
#
tokenchars "CWRD"
tokenid 0

# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
heapspace 68k

#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library wav

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#

resource CwordAppResource 		ui-object
resource CwordInterfaceResource		ui-object
resource CwordClueListResource		ui-object
resource CwordVisResource		object
resource CwordFileResource		ui-object
resource CwordQuickTipsResource		ui-object

resource AppSCMonikerResource 		read-only shared lmem
resource AppTCMonikerResource		read-only shared lmem

export CwordClueListClass
export CwordBoardClass
export CwordFileBoxClass
export CwordVisContentClass
export CwordGenViewClass
export CwordGenPenInputControlClass
export CwordFilteredFileSelectorClass
export CwordFileSelectorInteractionClass
export CwordApplicationClass









