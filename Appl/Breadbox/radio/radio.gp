name radio.app
longname "FM Radio"
type    appl, process, single
class   FMRadioProcessClass
appobj  FMRadioApp
tokenchars "FMRa"
tokenid 16431
platform geos201
exempt radiolib
library geos
library ui
library radiolib
resource AppResource object
resource Interface object
export FMRadioProcessClass
export FMTunerContentClass
export FMClockContentClass
export FMTriggerClass
export FMPresetClass
export FMInterClass
export OnOffTriggerClass

