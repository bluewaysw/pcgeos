#
# Name and type
#
name tginst.app
longname "FM Radio Installer"
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

usernotes "Copyright 1994-2002 Breadbox Computer Company LLC  All Rights Reserved"

