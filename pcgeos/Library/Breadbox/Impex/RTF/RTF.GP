name rtf.lib

longname "Breadbox RTF Translator"
tokenchars "TLTX"
tokenid 16431

type library, single

entry LibraryEntry

library	geos
library ui
library impex
library text
library ansic

resource WKFONTSRESOURCE read-only discardable lmem
export TransGetImportUI
export TransGetExportUI
export TransInitImportUI
export TransInitExportUI
export TransGetImportOptions
export TransGetExportOptions
export TransImport
export TransExport
export TransGetFormat

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

