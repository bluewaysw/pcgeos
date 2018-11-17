##############################################################################
#
# 	Copyright (c) MyTurn.com 2000.  All rights reserved.
#       MYTURN.COM CONFIDENTIAL
#
# PROJECT:	GlobalPC
# MODULE:	Internet Dialup Shortcut
# FILE: 	idialc.gp
# AUTHOR: 	David Hunter, Oct 17, 2000
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dhunter	10/17/00   	Initial Revision
#
# DESCRIPTION:
#	Geode parameters for idialc
#
#	$Id$
#
###############################################################################
#
# Permanent name
#
name idialc.lib
#
# Long name
#
longname "IDialup Control"
#
# Desktop-related definitions
#
tokenchars "IDIC"
tokenid 0
#
# Specify geode type
#
type	library, single
#
# Import library routine definitions
#
library geos
library	ui
library	socket
#
# Define resources other than standard discardable code
#
nosort
resource IDialControlUI		read-only ui-object shared
resource AUIMonikers		shared lmem read-only
resource CUIMonikers		shared lmem read-only
resource HelpStrings		shared lmem read-only
#
# new classes
#
export	IDialControlClass
export	IDialTriggerClass
