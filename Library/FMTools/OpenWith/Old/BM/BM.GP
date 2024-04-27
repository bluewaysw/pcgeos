#
name bm.app
#
# Long filename: This name can displayed by GeoManager, and is used to
# identify the application for inter-application communication.
#
ifdef ENG
ifdef R4	
	longname "BackDoor Man - R4E"
else
	longname "BackDoor Man - R3E"
endif
else
ifdef R4
	longname "BackDoor Man - R4D"
else
	longname "BackDoor Man - R3D"
endif
endif
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "FROC"
tokenid 17
#
# Specify geode type: This geode is an application, will have its own
# process (thread), and is not multi-launchable.
#
type	appl, process, single
#
# Specify the class name of the application Process object: Messages
# sent to the application's Process object will be handled by
# FSelSampProcessClass, which is defined in fselsamp.goc.
#
class	bmProcessClass
#
# Specify the application object: This is the object in the
# application's generic UI tree which serves as the top-level
# UI object for the application. See fselsamp.goc.
#
appobj	bmApp
#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
#
heapspace 4k
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library ansic
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
# For this application, as for most, we want a UI thread to run the
# object resources, so we mark them "ui-object". Had we wanted the
# application thread to run them, we would have marked them "object".
#
#
resource APPRESOURCE ui-object, discardable
resource INTERFACE ui-object, discardable
resource SENDTORSC ui-object, discardable
resource ABOUTRSC ui-object, discardable
resource TOKENRSC ui-object, discardable
resource STRINGS shared, lmem, read-only
resource BUBBLEHELP shared, lmem, read-only
#
#
#
usernotes "'BackDoor Man'\rCopyright (C) by MeyerK"