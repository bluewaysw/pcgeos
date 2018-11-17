#
# Name and type
#
# USE YOUR APP NAME HERE
name tpinst.app
# AND YOUR OWN LONG NAME
longname "Thinker Pro Installer"
type    appl, process, single

#
# Process
#
class   InstallProcessClass

#
# Application Object
#
appobj  InstallApp

#
# Tokens
#
tokenchars "SAMP"
tokenid 8

stack 8000

#
# Libraries
#
library geos
library ui
library ansic

#
# Resources
#
resource APPRESOURCE ui-object
resource INTERFACE ui-object

usernotes "Copyright 1994-2001 Breadbox Computer Company LLC"

