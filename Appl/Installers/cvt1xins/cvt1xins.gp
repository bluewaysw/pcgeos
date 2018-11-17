#
# Name and type
#
# USE YOUR APP NAME HERE
name cvt1xins.app
# AND YOUR OWN LONG NAME
longname "Convert 1.x Installer"
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
tokenchars "InSt"
tokenid 16431

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

usernotes "Copyright 1994-2005 Breadbox Computer Company LLC"

