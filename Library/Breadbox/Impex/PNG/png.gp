name png.lib

longname "PNG Translator"

tokenchars "TLGR"
tokenid 0

type library, single

entry LibraryEntry

library	geos
library ui
library impex
library extgraph
library color
library pnglib

resource ExportInterface object
resource ImportInterface object

export TransGetImportUI
export TransGetExportUI
export TransInitImportUI
export TransInitExportUI
export TransGetImportOptions
export TransGetExportOptions
export TransImport
export TransExport
export TransGetFormat

export PngImportGroupClass