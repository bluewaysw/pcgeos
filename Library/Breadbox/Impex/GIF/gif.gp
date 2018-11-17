name gif.lib

longname "Breadbox Gif Translator"

tokenchars "TLGR"
tokenid 0

type library, single

entry LibraryEntry

library geos
library ui
library impex
library ansic
library extgraph
library giflib

resource ExportInterface object

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

