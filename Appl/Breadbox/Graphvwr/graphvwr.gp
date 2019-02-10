#name mediavwr.app
name graphvwr.app

#longname "Media Viewer"
longname "Graphics Viewer"

#tokenchars "MdVr"
tokenchars "GrVr"
tokenid    16431

type appl, process, single

stack 4000

platform geos201

appobj BVApp

class BVProcessClass

library geos
library ui
library ansic
library extui

library giflib
exempt giflib


library thumbdb
library ijgjpeg

exempt thumbdb
exempt extui
exempt ijgjpeg

resource AppResource ui-object
resource Interface ui-object
resource MonikerRes ui-object
resource DisplayUI object shared read-only
resource DocumentUI object
resource FileSelUI ui-object
resource ObjBlTemplateResource ui-object read-only

# this resources are Graphics Viewer specific
resource BREADBOXMONIKERRESOURCE lmem read-only shared
resource BREADBOXMONIKERRESOURCE2 lmem read-only shared
resource InfoResource ui-object

export BVDocumentClass
export BVDocCtrlClass
export BVAppClass
export BVDynListClass
export BVBrowserInterClass

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"
