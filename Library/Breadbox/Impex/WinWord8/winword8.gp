#############################################################################
#
#  ==CONFIDENTIAL INFORMATION== 
#  COPYRIGHT 1994-2000 BREADBOX COMPUTER COMPANY --
#  ALL RIGHTS RESERVED  --
#  THE FOLLOWING CONFIDENTIAL INFORMATION IS BEING DISCLOSED TO YOU UNDER A
#  NON-DISCLOSURE AGREEMENT AND MAY NOT BE DISCLOSED OR FORWARDED BY THE
#  RECIPIENT TO ANY OTHER PERSON OR ENTITY NOT COVERED BY THE SAME
#  NON-DISCLOSURE AGREEMENT COVERING THE RECIPIENT. USE OF THE FOLLOWING
#  CONFIDENTIAL INFORMATION IS RESTRICTED TO THE TERMS OF THE NON-DISCLOSURE
#  AGREEMENT.
#  
#  Project: Word For Windows Translation Library
#  File:    winword8.gp
#  
#############################################################################

name winword8.lib

longname "Breadbox Word 8 Translator"
tokenchars "TLTX"
tokenid 16431
usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

type    library, single

entry   TransLibraryEntry

library	geos
library impex
library ansic
library text
library sstor
library wfwlib

resource FormatStrings			lmem shared read-only

export TransGetImportUI
export TransGetExportUI
export TransInitImportUI
export TransInitExportUI
export TransGetImportOptions
export TransGetExportOptions
export TransImport
export TransExport
export TransGetFormat

