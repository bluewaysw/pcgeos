##############################################################################
#
# PROJECT:	Breadbox Flashcard
# FILE:		flash.gp
#
# AUTHOR:		John F. Howard, 9/97
#
# DESCRIPTION:	This file contains Geode definitions for the Flashcard
#              program
#
#
##############################################################################
#
# Permanent name:
name flash.app
#
# Long filename:
longname "Flash Card"
#
# Specify geode type:
type appl, process, single
#
# Specify class name for application process.
class FlashCardProcessClass
#
# Specify application object.
appobj FlashCardApp
#
# Token:
tokenchars "FlCd"
tokenid 16431
#
# Heapspace: 
# To find the heapspace use the Swat "heapspace" command.

#
# Libraries:
library geos
library ui
library text
library ansic
library math
#
# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource DOCUMENTUI object
resource TEXTSTRINGS data object
resource LOGORESOURCE data object
resource FCAPPICONS data
resource FCDOCICONS data
# for the password stuff
resource PASSWORDWITHHINTRESOURCE ui-object
resource CHANGEPASSWORDRESOURCE ui-object
resource PWDSTRINGS read-only lmem
#
# platform
platform geos201
#
# classes
export VisFlashContentClass
export VisTitleTextClass
#export VisFCButtonClass
export VisFlashDeckClass
export VisFlashCardClass
export VisFCCompClass
export TextEnableClass
export FlashApplicationClass
export FlashDocumentClass
export FlashDocCtrlClass

usernotes "Copyright 1994-2001 Breadbox Computer Company LLC All Rights Reserved"

