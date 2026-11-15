##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	
# FILE:		htjpeg.gp
#
# AUTHOR:	
#
#
# 
#
#	$Id: htjpeg.gp,v 1.1 97/04/07 11:50:07 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a client geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name htjpeg.lib
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "WWW HTJPEG Library"
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "HTJP"
tokenid 0
#
# Specify geode type: is an application, and will have its own thread started
# for it by the kernel.
#
type	library, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the HelloProcessClass, which is defined in hello2.goc.
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library ansic
library netutils noload
library htcore
library uigenera
library htconv
#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
#resource DataBlock		read-only shared lmem
resource JpegFixedCodeC		read-only shared fixed code

export HTJPEGClass






