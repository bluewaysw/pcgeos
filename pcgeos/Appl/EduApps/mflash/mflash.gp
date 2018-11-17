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

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource VARIOUSJUNK lmem read-only
#resource LOGORESOURCE lmem read-only
resource OPTIONSDIALOGRESOURCE ui-object
resource LOGINDIALOGRESOURCE ui-object
resource PASSWORDWITHHINTRESOURCE ui-object
resource CHANGEPASSWORDRESOURCE ui-object
resource PWDSTRINGS read-only lmem

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


