name            nviewlib.lib
longname        "NView Viewer Library"

type            library, single

tokenchars      "NVIL"
tokenid         16431

platform        n9000c

library         geos
library         ui
library         foam
library         text
library         viewer
library         ansic

library         htmlpars
exempt          htmlpars

library         rtflib
exempt          rtflib

resource        THEVIEWERUI object read-only shared
resource        PROGRESSDIALOGTEMPLATE object read-only shared
resource        STRINGRESOURCE lmem read-only shared

export          TVOPEN
export          TVDETACH
export          TVCHANGEDOCUMENT
export          TVCLOSE

export          DocViewDialogClass
export          DocViewContentClass

