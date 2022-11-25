##############################################################################
#
#	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	PC SDK
# MODULE:	Sample Library -- Mandelbrot Set Library
# FILE:		mset.gp
#
# AUTHOR:	Paul DuBois, Aug  3, 1993
#
# DESCRIPTION:
#	geode parameters file for mset library
#
#	$Id: mset.gp,v 1.1 97/04/07 10:43:34 newdeal Exp $
#
##############################################################################
#

#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name mset.lib

#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname	"Mandelbrot Set Library"
tokenchars	"MSET"
tokenid		0

#
# Specify geode type: is a library
#
type	library, single

#
# Libraries: list which libraries are used by the application.
#
library	geos
library ui
library ansic

# this resource holds text strings for the controllers
resource ControlStrings         lmem      read-only shared

# these resources hold monikers for the controllers
resource ColorToolMonikerResource lmem read-only shared

#   template resources for the MSetColorControlClass
#   these resources are described in colorCtr.goc 
resource MSetColorControlUI     ui-object read-only shared
resource MSetColorControlToolUI ui-object read-only shared

#   template resources for the MSetPrecisionControlClass
#   these resources are described in preciCtr.goc 
resource MSetPrecisionControlUI     ui-object read-only shared
resource MSetPrecisionControlToolUI ui-object read-only shared

#
# Export classes
#	These are the classes exported by the library
#
export MSetClass
export MSetColorControlClass
export MSetPrecisionControlClass

#
# Routines
#	These are the routines exported by the library	
#
export FIXNUMUMULT
export FIXNUMUMULTTIMES2
export FIXNUMADD
export FIXNUMSUB
export FIXNUMTOASCII
