##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		chooseUI.gp
#
# AUTHOR:	Tony, 10/89
#
#
# Parameters file for: chooseUI.geo
#
#	$Id: chooseui.gp,v 1.1 97/04/04 15:35:21 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name chooseUI.app
#
# Long name
#
longname "Choose User Interface"
#
# Desktop-related definitions
#
tokenchars "ChUI"
tokenid 0
#
# Specify geode type
#
type	appl, process
#
# Specify class name for process
#
class	ChooseUIClass
#
# Specify application object
#
appobj	ChooseUI
#
# Import library routine definitions
#
library	geos
library	ui
#
# Define resources other than standard discardable code
#
resource Interface ui-object
