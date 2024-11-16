/* identifiers for list of formats which can be imported */
#define FORMAT_HPGL 1
#define FORMAT_CGM  2

/*
 * Data block passed between TransGet???portOptions and Trans???port
 */
struct ie_uidata {
  word booleanOptions;
};
