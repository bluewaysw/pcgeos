name mflash.app
longname "Math Flash!"
type    appl, process, single
class   MFlashProcessClass
appobj  MFlashApp
tokenchars "MFl3"
tokenid 16431

# Libraries

platform geos201

library geos
library ui
library ansic
library text
library treplib

exempt treplib


# Resources

resource AppResource ui-object
resource Interface ui-object
resource VariousJunk lmem read-only
#resource LOGORESOURCE lmem read-only
resource OptionsDialogResource ui-object
resource LoginDialogResource ui-object
resource PasswordWithHintResource ui-object
resource ChangePasswordResource ui-object
resource PwdStrings read-only lmem

export MFlashAppClass
export MFlashViewClass
export MFlashContentClass
export MFlashPrimaryClass
export BoxClass
export CardsClass
export LargeDigitLinesClass
export StatusTextClass
export LoginDialogClass
export OptionsDialogClass

#stack 9216

usernotes "Copyright 1994-2001 Breadbox Computer Company LLC All Rights Reserved"


