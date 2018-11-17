#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a client geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name hiho.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "Marble Solitaire"
#
# Specify geode type: is an application, and will have its own thread started
# for it by the kernel.
#
type    appl, process, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the HelloProcessClass, which is defined in hello.goc.
#
class   HiHoProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application. See hello.goc.
#
appobj  HiHoApp
#
# Token: this four-letter+integer name is used by GeoManager to locate the icon
# for this application in the token database. A tokenid of 0 is known symbolicly
# as MANUFACTURER_ID_GEOWORKS
#
tokenchars "HiHo"
tokenid 16431
#
# Libraries: list which libraries are used by the application.
#
platform gpc12
library geos
library ui
library ansic
library game
library sound

exempt game
exempt sound

#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource APPRESOURCE object
resource INTERFACE object
resource WINMONIKERRESOURCE object
resource LOSEMONIKERRESOURCE object
#resource INTERFACESCORES object
#resource INTERFACEABOUT object
resource INTERFACEOPTIONS object
resource INTERFACEVIEW object
resource INTERFACEDIALOG1 object
resource INTERFACEDIALOG2 object
#resource STRINGSRESOURCE lmem read-only shared discardable
resource QTIPSRESOURCE object
resource GRAPHICSRESOURCE data

export HiHoProcessClass
export HiHoViewClass
export HiHoContentClass
export HiHoTimerClass
export HiHoAppClass
export HiHoPauseInterClass

