##############################################################################
#
#
# PROJECT:	Test Applications
# MODULE:	Snake
# FILE:		snake.gp
#
# AUTHOR:		jfh  6/05
#
#
##############################################################################
name snake.app
longname "Snake"

type appl, process, single

class SnakeProcessClass
appobj SnakeApp

tokenchars "SnkA"
tokenid 16431

platform geos201
library geos
library ui
library game
library ansic

resource AppResource ui-object
resource Interface ui-object
resource AppIcons data object
resource StringsResource data object

export SnakeApplicationClass
export SnakePrimaryClass
export SnakeBoardClass

usernotes "Copyright 1994-2005  Breadbox Computer Company LLC  All Rights Reserved"

