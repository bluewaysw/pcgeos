##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Spline Edit object
# FILE:		spline.gp
#
# AUTHOR:	Chris Boyke
#
# DESCRIPTION:
#
# RCS STAMP:
#	$Id: spline.gp,v 1.1 97/04/07 11:10:02 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name spline.lib
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Spline library"
tokenchars	"SPLN"
tokenid		0
#
# Specify geode type: is a library
#
type	library, single
#
#
# Libraries: list which libraries are used by this one
#
library	geos
library	ui
#
#
# Specify alternate resource flags for anything non-standard
nosort
resource BlendCode			code read-only shared
resource SplineAttrCode			code read-only shared
resource SplineOperateCode		code read-only shared
resource SplinePtrCode			code read-only shared
resource SplineSelectCode		code read-only shared
resource SplineUtilCode			code read-only shared
resource SplineObjectCode		code read-only shared
resource SplineMathCode			code read-only shared
resource SplineGStringCode		code read-only shared
resource SplineInitCode			code read-only shared
resource SplineControlCode		code read-only shared
resource MarkerGStringUI		lmem, read-only, shared
resource StringsUI			lmem, read-only, shared
resource Strings			lmem
resource MarkerControlUI		ui-object
resource PointUI			ui-object, read-only, shared
resource PointToolUI			ui-object, read-only, shared
resource PolylineUI			ui-object, read-only, shared
resource PolylineToolUI			ui-object, read-only, shared
resource SmoothnessUI			ui-object, read-only, shared
resource SmoothnessToolUI		ui-object, read-only, shared
resource OpenCloseUI			object
resource OpenCloseToolUI		object
resource SplineClassStructures		fixed read-only shared
#
# Exported classes: list classes which are defined by the library here.
#
export VisSplineClass
export SplineMarkerControlClass
export SplinePointControlClass
export SplinePolylineControlClass
export SplineSmoothnessControlClass
export SplineOpenCloseControlClass

#
# Exported routines:
#
export	Blend

incminor

publish	BLEND

#
# XIP-enabled
#
