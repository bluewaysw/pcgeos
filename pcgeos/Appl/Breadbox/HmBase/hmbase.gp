
#**************************************************************
# *  ==CONFIDENTIAL INFORMATION==
# *  COPYRIGHT 1994-2000 BREADBOX COMPUTER COMPANY --
# *  ALL RIGHTS RESERVED  --
# *  THE FOLLOWING CONFIDENTIAL INFORMATION IS BEING DISCLOSED TO YOU UNDER A
# *  NON-DISCLOSURE AGREEMENT AND MAY NOT BE DISCLOSED OR FORWARDED BY THE
# *  RECIPIENT TO ANY OTHER PERSON OR ENTITY NOT COVERED BY THE SAME
# *  NON-DISCLOSURE AGREEMENT COVERING THE RECIPIENT. USE OF THE FOLLOWING
# *  CONFIDENTIAL INFORMATION IS RESTRICTED TO THE TERMS OF THE NON-DISCLOSURE
# *  AGREEMENT.
# **************************************************************/

##############################################################################
#
# PROJECT:	Breadbox GPCBase
# FILE:		gpcbase.gp
#
# AUTHOR:		John F. Howard, 11/98
#
# DESCRIPTION:	This file contains Geode definitions for the
#               program
#
#
##############################################################################
#
# Permanent name:
name hmbase.app
#
# Long filename:
longname "HomeBase"
#
# Specify geode type:
type	appl, process, single
#
# Specify class name for application process.
class	GPCBaseProcessClass
#
# Specify application object.
appobj	GPCBaseApp
#
# Token:
tokenchars "HBaa"
tokenid 16431
#
# Heapspace: 
# To find the heapspace use the Swat "heapspace" command.
heapspace 8000
#
# process stack space (default is 2000):
stack 7000
#
# Libraries:
library	geos
library	ui
library ansic
library text
library spool
library math
#
#
# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource NAVBUTTONS ui-object
resource MENU ui-object
resource DOCUMENTUI object
resource DIALOGS ui-object
resource IMPEXDIALOGS ui-object
resource CHANGEATTRSDIALOG ui-object
resource CREATEREPDIALOG ui-object
resource HBAPPICONS data lmem read-only shared
resource TEXTSTRINGS data lmem
resource HBASEBUTTONRESOURCE data
#resource LOGORESOURCE  data lmem            
resource FINDBUTTONRESOURCE data lmem read-only shared
resource REPORTBUTTONRESOURCE data lmem read-only shared

# classes
export GPCBaseApplicationClass
export RepeatingTriggerClass
export GPCBaseDocumentClass
export GPCBaseFieldTextClass
export GPCBaseDisplayTextClass
export GPCBaseFindTextClass
export GPCBaseEnterTextClass
export GPCBaseVLTextClass
export GPCReportInteractionClass
export GPCBasePrimaryClass

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

