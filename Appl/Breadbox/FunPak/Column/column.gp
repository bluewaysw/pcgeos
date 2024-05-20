name column.app
longname "Columns"

type appl, process, single

class ColumnsProcessClass
appobj ColumnsApp

tokenchars "COLU"
tokenid 16431

library geos
library ui
library game
library sound

resource AppResource ui-object
resource Interface ui-object
resource APPICONS data object
resource QTipsResource ui-object

export ColumnsBoardViewClass
export ColumnsBoardClass
export ColumnsApplicationClass
