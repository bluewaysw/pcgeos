name column.app
longname "Columns II"

type appl, process, single

class ColumnsProcessClass
appobj ColumnsApp

tokenchars "COL2"
tokenid 16431

library geos
library ui
library game

resource AppResource ui-object
resource Interface ui-object
resource MONIKERRESOURCE  data object
resource StringsResource  data 

export ColumnsBoardViewClass
export ColumnsBoardClass

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"
