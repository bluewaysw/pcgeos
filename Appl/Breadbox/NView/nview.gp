name            nview.app
longname        "NView File Viewer"

type            appl, process, single
class           DocViewProcessClass
appobj          DocViewApp

export          FilterFileOpenControlClass

stack           8192
heapspace       60k

tokenchars      "NVIW"
tokenid         16431

platform        n9000c

library         geos
library         ui
library         foam
library         ansic
library         viewer

resource        APPRESOURCE object
resource        INTERFACE object

