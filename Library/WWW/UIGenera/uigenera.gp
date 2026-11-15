##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	
# FILE:		uigenerator.gp
#
# AUTHOR:	Edwin Yu, Apr 23, 1996
#
#
# 
#
#	$Id: uigenera.gp,v 1.1 97/04/07 11:49:26 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name    uigenera.lib
#
# Long filename: this name can be displayed by GeoManager, and is used to 
# identify the application for inter-application communication.
#
longname        "UI Generator Library"
tokenchars      "UIGN"
tokenid         0
#
#       Specify geode type
#
type            library, single
#
#       Libraries
#
library geos
library ui
library ansic
library text
library pmanager
library htcore
library htmem
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource MouseImage      read-only shared data
resource BmpData      read-only shared data
#
#       Export routines:
#
export UIGeneratorClass
export HTGenImageClass


