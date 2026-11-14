##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	
# FILE:		pmanager.gp
#
# AUTHOR:	Edwin Yu, Apr 23, 1996
#
#
# 
#
#	$Id: pmanager.gp,v 1.4.10.2 97/09/15 23:51:33 edwin Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name    pmanager.lib
#
# Long filename: this name can be displayed by GeoManager, and is used to 
# identify the application for inter-application communication.
#
longname        "Presentation Manager Library"
tokenchars      "PMLB"
tokenid         0
#
#       Specify geode type
#
type            library, single
#
#       Libraries
#
library geos
library ansic
library ui
library text
library htcore
library htmem
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
#resource HTACCESSDATA      shared lmem
#resource SELECTIONRES ui-object shared read-only
#
#       Export routines:
#
export PresentationManagerClass
export HTMLContentClass
export PMSearchCtrClass
export UpdateGlobalSearchVariables

