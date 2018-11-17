##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Maze
# FILE:		maze.gp
#
# AUTHOR:	Jimmy, 11/90
#
#	$Id: maze.gp,v 1.1 97/04/04 16:45:46 newdeal Exp $
#
##############################################################################
name maze.lib
type appl, process, single
longname "Maze"
tokenchars "SSAV"
tokenid 0
library saver
library	geos
library	ui

class	MazeProcessClass
appobj  MazeApp

export MazeApplicationClass
#export MazeContentClass
#export MazePrimaryClass
