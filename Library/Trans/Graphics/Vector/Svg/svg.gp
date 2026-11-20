name svg.lib
longname "SVG Translator"
tokenchars "TLGR"
tokenid 0

type library, single
entry LibraryEntry

library geos
library impex
library svglib

resource INIT read-only code shared
resource ASM read-only code shared
resource InfoResource lmem read-only shared

export TransGetImportUI
export TransGetExportUI
export TransInitImportUI
export TransInitExportUI
export TransGetImportOptions
export TransGetExportOptions
export TransImport
export TransExport
export TransGetFormat
