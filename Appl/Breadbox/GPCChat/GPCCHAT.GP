#
#  ==CONFIDENTIAL INFORMATION==
#  COPYRIGHT 1994-2000 BREADBOX COMPUTER COMPANY --
#  ALL RIGHTS RESERVED  --
#  THE FOLLOWING CONFIDENTIAL INFORMATION IS BEING DISCLOSED TO YOU UNDER A
#  NON-DISCLOSURE AGREEMENT AND MAY NOT BE DISCLOSED OR FORWARDED BY THE
#  RECIPIENT TO ANY OTHER PERSON OR ENTITY NOT COVERED BY THE SAME
#  NON-DISCLOSURE AGREEMENT COVERING THE RECIPIENT. USE OF THE FOLLOWING
#  CONFIDENTIAL INFORMATION IS RESTRICTED TO THE TERMS OF THE NON-DISCLOSURE
#  AGREEMENT.
#

name gpcchat.app
longname "Chat"

type    appl, process, single
class   IRCProcessClass
appobj  IRCApp
tokenchars "irc3"
tokenid 16431
stack 8000

library geos
library ui
library socket
library ansic
library text
library accpnt
library parentc

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource CHANDISPLAYRESOURCE ui-object
resource ICONS data object
#resource LOGORESOURCE data object
resource PRIVDBOXRESOURCE ui-object
resource TEXTSTRINGS data object

export IRCApplicationClass
export GenTextLimitClass
export ChannelGenDisplayClass
export NickGenTextClass
export SortDynamicListClass
export MyGenFileSelectorClass
export ChatTextClass
export PrivTextClass
export ChatGenInteractionClass

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"


