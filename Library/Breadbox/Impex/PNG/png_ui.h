/*
 * Data block passed between TransGet???portOptions and Trans???port
 */

typedef enum {
    PNG_AT_TRESHOLD = 0,
    PNG_AT_BLEND
} aTransformMethod;

struct ie_uidata {
    aTransformMethod method;
    // byte alphaThreshold;
    // RGBValue blendColor;
};
