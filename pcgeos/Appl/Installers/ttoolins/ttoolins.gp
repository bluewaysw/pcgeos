# Name and type
name ttoolins.app
longname "TimeTool Installer"
type    appl, process, single

# Process
class   InstallProcessClass

# Application Object
appobj  InstallApp

# Tokens
tokenchars "TTBi"
tokenid 16431

# Heapspace:
# To find the heapspace use the Swat "heapspace" command.
heapspace 5000

# Libraries
library geos
library ui
library ansic

# Resources
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource TTIAPPICONS data object

usernotes "Copyright 1994/1998 - Breadbox Computer  All rights Reserved"

