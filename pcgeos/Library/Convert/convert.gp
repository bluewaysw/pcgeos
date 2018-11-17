##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	Geode Parameters
# FILE:		convert.gp
#
# AUTHOR:	Adam de Boor, Aug 26, 1992
#
#
# 
#
#	$Id: convert.gp,v 1.1 97/04/04 17:52:29 newdeal Exp $
#
##############################################################################
#
name convert.lib
type library, single

#
# Token must be FMTL for file manager to find us
#
tokenchars "CVRT"
tokenid 0

longname "1.X Document Converter"

library geos
library ui
library grobj

# resources
nosort
resource VMCode					read-only code shared
resource ConvertDrawDocumentCode		read-only code shared
resource GStringCode				read-only code shared
resource VMUtils				read-only code shared
resource ConvertText				read-only code shared
resource ConvertScrapbook			read-only code shared
resource ConvertGeoDex				read-only code shared
#
# Other things for everyone else.
#
export ConvertVMFile
export ConvertDrawDocument
export ConvertGString
export ConvertGetVMBlockList
export ConvertDeleteViaBlockList
export ConvertOldGeoWriteDocument
export ConvertOldTextObject
export ConvertOldTextTransfer
export ConvertOldScrapbookDocument
export ConvertOldGeoDexDocument
