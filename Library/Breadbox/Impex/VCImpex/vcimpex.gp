name vcimpex.lib

longname        "VConvert CGM/HPGL Translator"
tokenchars      "TLGR"
tokenid		0

type library, single

entry LibraryEntry

library	geos
library ui
library impex
library ansic
library math
library meta

export TransGetImportUI
export TransGetExportUI
export TransInitImportUI
export TransInitExportUI
export TransGetImportOptions
export TransGetExportOptions
export TransImport
export TransExport
export TransGetFormat
