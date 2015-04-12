attribute highp vec4 pos;

uniform highp mat4 qt_Matrix;
uniform highp vec4 uScaleOffset;

void main(void)
{
    vec2 p = (pos.xy + uScaleOffset.zw) * uScaleOffset.xy;
    gl_Position = qt_Matrix * vec4(p, 0, 1);
}
