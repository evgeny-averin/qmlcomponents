uniform lowp vec4 uColor;
uniform lowp float qt_Opacity;

void main(void)
{
    gl_FragColor = vec4(uColor.xyz, 1.) * uColor.w * qt_Opacity;
}
