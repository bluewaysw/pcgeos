/* flags to be used in "options" parameter of ParseHTMLFile() */
#define HTML_READ_FAST          1       // ignore formatting, tables etc.
#define HTML_MONOCHROME         2
#define HTML_NO_BACKGROUND      4       // not implied by MONOCHROME in WM 2
#define HTML_NO_REDUCED_SIZES   8       // new for GPC: no smaller font sizes
#define HTML_JAVASCRIPT         0x1000  // Parse JavaScript
#define HTML_ADD_TABLES         0x2000
#define HTML_ADD_HYPERLINKS     0x4000
#define HTML_ADD_MARGIN         0x8000
