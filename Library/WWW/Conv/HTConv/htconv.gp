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
#	$Id: htconv.gp,v 1.1.11.2 97/09/25 18:36:59 kkee Exp $
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
library html

export HTConverterClass
