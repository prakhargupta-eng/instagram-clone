#version 460 core
precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    // Animated scanning line grid
    float scanline = sin(uv.y * 300.0 + uTime * 6.0) * 0.05;
    
    // CRT screen vignette shadow
    vec2 d = abs(uv - 0.5) * 1.5;
    float vignette = 1.0 - dot(d, d) * 0.28;
    
    // Blended retro noise colors
    vec3 overlay = vec3(0.5 + 0.5 * scanline, 0.48, 0.52 + 0.3 * scanline);
    
    fragColor = vec4(overlay * vignette, 0.12);
}
