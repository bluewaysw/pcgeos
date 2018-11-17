name row4.app
longname "Four in a Row"
type    appl, process, single
class   Row4ProcessClass
appobj  Row4App
tokenchars "FRow"
tokenid 16431

platform gpc12
library geos
library ui
library ansic
library sound

exempt sound

stack 6000
resource APPRESOURCE object
resource INTERFACE object
resource WIN1MONIKERRESOURCE object
resource WIN2MONIKERRESOURCE object
resource WINCMONIKERRESOURCE object
resource TIEMONIKERRESOURCE object
#resource INTERFACEABOUT object
resource INTERFACEWIN1 object
resource INTERFACEWIN2 object
resource INTERFACEWINC object
resource INTERFACETIE object
#resource STRINGSRESOURCE lmem read-only shared discardable
resource RESOURCEPICTURES data
resource QTIPSRESOURCE object

export Row4ViewClass
export Row4ContentClass

