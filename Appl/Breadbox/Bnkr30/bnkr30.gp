
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
# TESTING 1-2-3
##############################################################################
#
# Permanent name:
name bnkr30.app
#
# Long filename:
longname "Banker 3.0"
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
tokenchars "BKR3"
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
platform geos201

# Libraries:
library	geos
library	ui
library ansic
library text
library spool
library math
#library bnkrdraw
#ifndef COMPILEGPC
library   n2txt
#endif
exempt n2txt

# Resources:
resource AppResource ui-object
resource Interface ui-object
resource Dialogs ui-object
resource AccountDialogs ui-object
resource CatPayDialogs ui-object
resource MultisDialogs ui-object
resource ImpExDialogs ui-object
resource ReconcileDialogs ui-object
resource ReportDialogs ui-object
resource CkPrintResource ui-object
resource Menu ui-object
resource DocumentUI object
resource AppIcons data object
#resource BtnIcons data object
#resource REPORTBUTTONRESOURCE data object
resource CatStrings data object
resource TextStrings data object
#resource LogoResource  data object
resource ViewItemTemplateResource ui-object
resource XferAcctItemTemplateResource ui-object
resource CopyCatsResource ui-object

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
#export GPCBnkrFormInteractionClass
#export WelcomeGenInteractionClass
#export CatCopyFileSelectorClass
export RegGenInteractionClass
export RegGenDynamicListClass
export CatPayGenInteractionClass
export NewPayGenInteractionClass
export MultiDBGenInteractionClass
export AddMultiDBGenInteractionClass
export CopyFileSelectorClass

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

