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
resource AppResource ui-object
resource Interface ui-object
resource DocumentUI object
resource TextStrings data object
resource LogoResource data object
resource FCAppIcons data
resource FCDocIcons data
# for the password stuff
resource PasswordWithHintResource ui-object
resource ChangePasswordResource ui-object
resource PwdStrings read-only lmem
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
