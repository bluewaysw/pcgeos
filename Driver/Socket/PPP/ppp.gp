##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
#			GEOWORKS CONFIDENTIAL
#
# PROJECT:	PPP Driver
# FILE:		ppp.gp
#
# AUTHOR:	Jennifer Wu, Apr 19, 1995
#
# DESCRIPTION:
#		Parameters file for PPP driver.
#
#	$Id: ppp.gp,v 1.8 97/11/20 18:46:43 jwu Exp $
#
##############################################################################

#
name 	ppp.drvr

#
type	driver, single
#, discardable-dgroup

#
longname	"PPP Driver"
tokenchars	"SKDR"
tokenid		0

#
# Libraries used
#
library	geos
library	netutils
library ansic
library accpnt

#ifdef PRODUCT_RESPONDER
#library foam
#library vp
#library security
#library contlog
#endif	# PRODUCT_RESPONDER

#ifdef STAC_LZS
#library	lzs
#endif

#ifdef MPPC
#library mppc
#endif

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources can be ommitted).
#
resource	ResidentCode		fixed code read-only shared
resource	PPPClassStructures	fixed read-only shared
resource 	PPPAddrCtrlUI		ui-object read-only shared
resource	PPPPasswordUI		ui-object read-only shared
resource	Strings			shared lmem read-only

#
# Exported classes
#
export PPPAddressControlClass
export PPPSpecialTextClass
