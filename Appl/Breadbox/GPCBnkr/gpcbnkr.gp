
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
# PROJECT:	GPC Banker
#
# AUTHOR:		John F. Howard, 12/98
#
# DESCRIPTION:	This file contains Geode definitions for the Banker
#               program
#
#
##############################################################################
#
# Permanent name:
name gpcbnkr.app
#
# Long filename:
longname "Banker"
#
# Specify geode type:
type	appl, process, single
#
# Specify class name for application process.
class	GPCBnkrProcessClass
#
# Specify application object.
appobj	GPCBnkrApp
#
# Token: use 16431 for Breadbox Apps
tokenchars "BNKR"
tokenid 16431
#
# Heapspace: 
# To find the heapspace use the Swat "heapspace" command.
# V0.4 heapspace was 6674
heapspace 8000
#
# process stack space (default is 2000):
stack 6000
#
# Libraries:
library	geos
library	ui
library ansic
library text
library spool
library math
library bnkrdraw
#ifndef COMPILEGPC
library   n2txt
#endif

# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource DIALOGS ui-object
resource ACCOUNTDIALOGS ui-object
resource CATPAYDIALOGS ui-object
resource MULTISDIALOGS ui-object
resource IMPEXDIALOGS ui-object
resource RECONCILEDIALOGS ui-object
resource REPORTDIALOGS ui-object
resource CKPRINTRESOURCE ui-object
resource MENU ui-object
resource DOCUMENTUI object
resource APPICONS data object
resource BTNICONS data object
resource REPORTBUTTONRESOURCE data object
resource CATSTRINGS data object
resource TEXTSTRINGS data object
resource LOGORESOURCE  data object
resource VIEWITEMTEMPLATERESOURCE ui-object
resource XFERACCTITEMTEMPLATERESOURCE ui-object
resource COPYCATSRESOURCE ui-object

# classes
export GPCBnkrVLTextClass
export GPCBnkrDocCtrlClass
export GPCBnkrDocumentClass
export GPCBnkrApplicationClass
export GPCBnkrCatGenTextClass
export FindGenTextClass
export AmountGenTextClass
export TaxGenBooleanClass
export GPCBnkrEntryInteractionClass
export GPCBnkrFormInteractionClass
export WelcomeGenInteractionClass
#export CatCopyFileSelectorClass
export RegGenInteractionClass
export RegGenDynamicListClass
export CatPayGenInteractionClass
export NewPayGenInteractionClass
export MultiDBGenInteractionClass
export AddMultiDBGenInteractionClass
export CopyFileSelectorClass

#usernotes "Copyright 1994-2000  Breadbox Computer Company  All Rights Reserved"
