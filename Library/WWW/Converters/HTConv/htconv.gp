##############################################################################
#
#	Copyright (c) Geoworks 1997.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	
# FILE:		htconv.gp
#
# AUTHOR:	Mingzhe Zhu, Feb  3, 1997
#
#
# 
#
#	$Id: htconv.gp,v 1.1 97/04/07 11:50:04 newdeal Exp $
#
##############################################################################
#
name htconv.lib

longname "WWW HTCONV Library"

tokenchars "HTCV"
tokenid 0

type	library, single

library geos
library ui
library ansic
library netutils noload
library htcore
library uigenera

export HTConverterClass
