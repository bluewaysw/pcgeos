# prints a mouse event when set in MouseDevHandler for the logibus driver
defsubr pme {} {
    var dx [read-reg bl] dy [read-reg ah] bb [read-reg bh]
    if {$dx > 127} {
	var dx [expr $dx-256]
    }
    if {$dy > 127} {
	var dy [expr $dy-256]
    }
    if {$bb & 4} {
	var buttons {  }
    } else {
	var buttons b0
    }
    if {$bb & 2} {
	var buttons [concat $buttons {  }]
    } else {
	var buttons [concat $buttons b1]
    }
    if {$bb & 1} {
	var buttons [concat $buttons {  }]
    } else {
	var buttons [concat $buttons b2]
    }
    if {$bb & 8} {
	var buttons [concat $buttons {  }]
    } else {
	var buttons [concat $buttons b3]
    }

    echo deltaX = $dx deltaY = $dy buttons = $buttons

    return 0
}
