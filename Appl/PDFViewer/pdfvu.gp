##############################################################################
#
# 	Copyright (c) GlobalPC 1999.  All rights reserved.
#       GLOBALPC CONFIDENTIAL
#
# PROJECT:	GEOS
# MODULE:	PDF Viewer
# FILE: 	pdfvu.gp
# AUTHOR: 	John Mevissen, Mar 26, 1999
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#	mevissen	3/26/99   	Initial Revision
#
# DESCRIPTION:
#	Application skeleton aped from sdk_c/document/multiview and
#		../dosfile.
#	PDF code ported from xpdf (source from //www.foolabs.com/xpdf)
#
#	$Id$
#
###############################################################################
#
name pdfvu.app
#
longname "PDF Viewer"
#
type	appl, process, single
#
class	PDFProcessClass
#
appobj	PDFApp
#
tokenchars "PDFV"
tokenid 0
#
#
heapspace 70k
stack 3000
#
library	geos
library ui
library ansic
library spool
#
#
resource DISPLAYUI object shared read-only
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource DOCUMENTUI object

resource ENCODINGS lmem read-only shared
resource OPTABLE   lmem read-only shared
resource FAXCODES  lmem read-only shared

resource APPSCICONRESOURCE lmem read-only shared
resource APPTCICONRESOURCE lmem read-only shared
#
#
export PDFDocumentClass
export PDFDocumentControlClass
export PDFImageInteractionClass
export PDFPageControlClass