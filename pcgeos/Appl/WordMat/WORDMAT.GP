
#**************************************************************
# *  ==CONFIDENTIAL INFORMATION==
# *  COPYRIGHT 1994-2000 BREADBOX COMPUTER COMPANY --
# *  ALL RIGHTS RESERVED  --
# *  THE FOLLOWING CONFIDENTIAL INFORMATION IS BEING DISCLOSED TO YOU UNDER A
# *  NON-DISCLOSURE AGREEMENT AND MAY NOT BE DISCLOSED OR FORWARDED BY THE
# *  RECIPIENT TO ANY OTHER PERSON OR ENTITY NOT COVERED BY THE SAME
# *  NON-DISCLOSURE AGREEMENT COVERING THE RECIPIENT. USE OF THE FOLLOWING
# *  CONFIDENTIAL INFORMATION IS RESTRICTED TO THE TERMS OF THE NON-DISCLOSURE
# *  AGREEMENT.
# **************************************************************/

#
# Permanent name: This is required by Glue to set the permanent name
# and extension of the geode. The permanent name of a library is what
# goes in the imported library table of a client geode (along with the
# protocol number). It is also what Swat uses to name the patient.
#
name     wordmat.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "Word Matcher"
#
# Specify geode type: This geode is an application, and will have its
# own process (thread).
#
type   appl, process, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the HelloProcessClass, which is defined in hello.goc.
#
class  WordMatcherProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application. See hello.goc.
#
appobj WordMatcherApp
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "WMat"
tokenid    16431
#
# Heapspace: This is roughly the non-discardable memory usage
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
# heapspace 18k
#

# Libraries: list which libraries are used by the application.
#
library geos
library ui
library ansic

library wmlib


export  WordMatcherViewClass
export  WordMatcherTextClass
export  WordSearchTextClass
export  GenStopTriggerClass
#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource APPRESOURCE             ui-object
resource INTERFACE               ui-object
# for the password stuff
resource PASSWORDWITHHINTRESOURCE ui-object
resource CHANGEPASSWORDRESOURCE ui-object
resource PWDSTRINGS read-only lmem

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

