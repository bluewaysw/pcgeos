name column.app
longname "Columns"

type appl, process, single

class ColumnsProcessClass
appobj ColumnsApp

tokenchars "COL2"
tokenid 16431

library geos
library ui
library game
library sound

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource APPICONS data object
resource QTIPSRESOURCE ui-object

export ColumnsBoardViewClass
export ColumnsBoardClass
export ColumnsApplicationClass
