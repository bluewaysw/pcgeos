/*
 * protoypes for experimental export module
 */
typedef struct {
  void          *VCES_private;
  AreaAttr      VCES_aa;
  LineAttr      VCES_la;
  TextAttr      VCES_ta;
} VCExportState;

typedef enum {
  VC_OBJ_INIT=1,
  VC_OBJ_LINE=16,
  VC_OBJ_POLYLINE,
  VC_OBJ_POLYGON,
  VC_OBJ_ARC,
  VC_OBJ_ARC_3P,
  VC_OBJ_RECT,
  VC_OBJ_ROUND_RECT,
  VC_OBJ_ELLIPSE,
  VC_OBJ_SPLINE,
  VC_OBJ_TEXT
} VCExportObjType;

typedef struct {
  VCExportObjType type;
  Boolean fill;
  union {

    struct {
      RectDWord bounds;
    } OBJ_INIT;

    struct {
      PointWWFixed p1,p2;
    } OBJ_LINE;

    struct {
      PointWWFixed p1,p2,p3,p4;
    } OBJ_RECT;

    struct {
      word numPoints;
      Point *p;
    } OBJ_POLY;
  } d;
} VCExportObjDesc;

Boolean VCExportObj(VCExportObjDesc *obj,VCExportState *state);

