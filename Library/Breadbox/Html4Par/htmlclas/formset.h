#define FORM_PASSWORD_CHARACTER '*'
#define MAX_FORM_ELEMENT_EDIT_TEXT_CHARS 200
#define FORM_TEXT_POINT_SIZE             12
#define FORM_TEXT_POINT_SIZE_TV          16
#define SELECT_LIST_MIN_WIDTH            18
#define MAX_FORM_ELEMENT_OPTION_LENGTH   200
#define FORM_MAX_CHARACTERS_IN_SUBMIT_OR_RESET_BUTTON  80
#define FORM_MAX_TEXT_SIZE               80       /* maximum visible field size */
#define FORM_STANDARD_TEXT_SIZE          30       /* default visible field size */
#define FORM_MAX_CHARACTERS_IN_TEXT_LINE 120
#define FORM_MAX_CHARACTERS_IN_TEXT_AREA MAX_STORED_CONTENT

word FormGetPointSize(void);
word FormGetFont(void);
void FormSetTextAttr(GStateHandle gstate);
