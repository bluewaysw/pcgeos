##############################################################################
#
# 	Copyright (c) MyTurn.com 2000.  All rights reserved.
#       MYTURN.COM CONFIDENTIAL
#
# PROJECT:	GlobalPC
# MODULE:	PhotoPC
# FILE: 	photopc.gp
# AUTHOR: 	David Hunter, Nov 08, 2000
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dhunter	11/08/00   	Initial Revision
#
# DESCRIPTION:
#	Geode parameters for photopc
#
#	$Id$
#
###############################################################################
#
# Permanent name
#
name photopc.lib
#
# Long name
#
longname "PhotoPC Camera Library"
#
# Desktop-related definitions
#
tokenchars "PPCL"
tokenid 17
#
# Specify geode type
#
type	library, single
#
# Import library routine definitions
#
platform geos201

library geos
library streamc
library ansic
exempt streamc

#
# Exported routines
#
export PPCOpen
export PPCSetResolution
export PPCSetFlash
export PPCSnapShot
export PPCErase
export PPCEraseAll
export PPCQuery
export PPCCount
export PPCGetFile
export PPCClose

