##############################################################################
#
#   Copyright (c) Cool Lava Productions -- All Rights Reserved
#                 Breadbox Computer Company
# PROJECT:  Kids' Numbers
# MODULE:   parameters file
# FILE:     Numbers.gp
#
# AUTHOR:   Duane Char
#
#
# RCS STAMP:
#
##############################################################################
#
name numbers.app
#
longname "Kids' Numbers"
#
type    appl, process, single
#
class   NumbersProcessClass
#
appobj  NumbersApp
#
tokenchars "NBRS"
tokenid 16431
#
platform geos201
#
library geos
library ui
library ansic
library math
#
resource AppResource ui-object
resource Interface ui-object
resource Editor ui-object
resource DocumentUI object
#resource StringResource data read-only
resource StringResource data object
resource LOGORESOURCE data object
# for the password stuff
resource PasswordWithHintResource ui-object
resource ChangePasswordResource ui-object
resource PwdStrings read-only lmem

export NumbersVisContentClass
export VisBoxClass
export TextEnableClass
export TextModifiedClass
export VMEEditorClass
export KNDocCtrlClass
export KNDocumentClass

usernotes "Copyright 1994-2001 Breadbox Computer Company LLC All Rights Reserved"

