#include <metal_stdlib>
using namespace metal;

#define PI 3.1416

// Searching for floor in fmod is as useless as searching for meaning in a
// Pauly Shore movie.
float mod(float x, float y) {
  return x - y * floor(x / y);
}

float3 mixColor(float3 colorA, float3 colorB, float amount) {
  float r = colorA.r * (1.0 - amount) + colorB.r * amount;
  float g = colorA.g * (1.0 - amount) + colorB.g * amount;
  float b = colorA.b * (1.0 - amount) + colorB.b * amount;
  return float3(r, g, b);
}

float3 lighter(float3 color, float amount) {
  float3 white = float3(1.0);
  return mixColor(color, white, amount);
}

float3 darker(float3 color, float amount) {
  float3 black = float3(0.0);
  return mixColor(color, black, amount);
}

float4 rollinWithMyHomies(float2 uv, float2 resolution, float time) {
  float r = PI * sin(time * 0.2);
  uv = float2x2(cos(r), sin(r), -sin(r), cos(r)) * (uv - 0.5);

  uv *= 1.4 + 0.5 * cos(time * 0.2);
  uv.y += time;
  uv = fract(uv);
  float stripes = 9.0;

  float2 p = (floor(uv * stripes * 10.0));
  float pattern = step(mod(p.x - p.y, 3.0), 1.0);
  float back = 0.8;
  float3 background = float3(0.9176, 0.8039, 0.2039);

  float2 cut = step(abs((uv - 0.5) * stripes * 2.0), float2(5.0));

  float black = mod(ceil(uv.y * stripes), 2.0);
  float white = 1.0 - black;

  float3 darkColor = darker(background, black);
  float3 lightColor = lighter(background, white);

  float alpha = 0.95;

  float3 color = mix(background, darkColor, alpha * black * cut.y * pattern);
  color = mix(color, lightColor, alpha * white * cut.y * pattern);

  pattern = 1.0 - pattern;
    
  float vb = mod(ceil(uv.x * stripes), 2.0);
  black = (vb * pattern);
  darkColor = darker(background, black);

  color = mix(color, darkColor, alpha * vb * cut.x * pattern);

  float vw = 1.0 - vb;
  white = vw * pattern;
  lightColor = lighter(background, white);
  color = mix(color, lightColor, alpha * vw * cut.x * pattern);

  float2 red = step(stripes * 2.0 - 1.0, floor(abs(uv - 0.5) * stripes * 4.0));

  color = mix(color, float3(red.x * pattern, 0.0, 0.0), alpha * red.x * pattern);
  color = mix(color, float3(red.y * pattern, 0.0, 0.0), alpha * red.y * pattern);

  return float4(color, 1.0);
}

kernel void asIf(texture2d<float, access::write> o[[texture(0)]],
                 constant float &time [[buffer(0)]],
                 constant float2 *touchEvent [[buffer(1)]],
                 constant int &numberOfTouches [[buffer(2)]],
                 ushort2 gid [[thread_position_in_grid]]) {
  int width = o.get_width();
  int height = o.get_height();
  float2 res = float2(width, height);
  float2 uv = (float2(gid) * 2.0 - res.xy) / res.y;

  float4 color = rollinWithMyHomies(uv, res, time);
  o.write(color, gid);
}
