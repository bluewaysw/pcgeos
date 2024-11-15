##############################################################################
#
#	Copyright (c) Breadbox Computer Company LLC -- All Rights Reserved
#
# PROJECT:	Educational Applications
# MODULE:	HangMan app
# FILE:		hangman.gp
#
# AUTHOR:	John Howard 11/1/01
#
#
##############################################################################
#
# Permanent name:
name hangman.app
#
# Long filename:
longname "Hang Man"
#
# Specify geode type:
type	appl, process, single
#
# Specify class name for application process.
class	HangManProcessClass
#
# Specify application object.
appobj	HangManApp
#
# Token:
tokenchars "HgMn"
tokenid 16431
#
# Heapspace:
#heapspace 3490
#
# Libraries:
library	geos
library	ui
library ansic
library math
library wmlib
exempt wmlib
#
# platform
platform geos201
#
# Resources:
resource AppResource ui-object
resource Interface ui-object
resource Appicons data object
resource Strings data object
#
# Other classes
export	HangManViewClass

usernotes "Copyright 1994-2001 Breadbox Computer Company LLC All Rights Reserved"

