module Shaders exposing
    ( vertexShader
    , texturedRectFragmentShader
    , coloredRectFragmentShader
    , animatedRectFragmentShader
    )

import Math.Vector2 exposing (Vec2, vec2)
import Math.Vector3 exposing (Vec3, vec3)
import Math.Vector4 exposing (Vec4, vec4)
import Math.Matrix4 exposing (Mat4)

import WebGL exposing (Texture, Shader)


{-| A generic enough vertex shader. Can be generally used if the fragment 
  shader needs to display texture(s).
-}
vertexShader =
    [glsl|
attribute vec2 position;

uniform mat4 transform;
uniform mat4 cameraProj;

// Value passed to fragment shader

varying vec2 vcoord;

void main() {

    // Final screen vertex position
    vec4 screenPosition = cameraProj * transform * vec4(position, 0, 1);
    gl_Position = screenPosition;

    // Pass current coordinates to fragment shader
    vcoord = position.xy;
}
|]


{-| Color the whole area in a single color. Useful while prototyping.
-}
coloredRectFragmentShader =
    [glsl|
precision mediump float;

uniform vec3 color;

varying vec2 vcoord; // Unused

void main() {
    gl_FragColor = vec4(color, 1);
}
|]


{-| Render a sprite using a portion of a larger texture atlas.
-}
texturedRectFragmentShader =
    [glsl|
precision mediump float;

uniform sampler2D atlas;
uniform vec2 atlasSize;
uniform vec2 spriteSize;
uniform int spriteIndex;

// Incoming values from vertex shader

varying vec2 vcoord;

void main() {

    // Recast as float
    float spriteIndex = float(spriteIndex);

    float w = atlasSize.x;
    float h = atlasSize.y;

    // Normalize sprite size (0.0-1.0)
    float dx = spriteSize.x / w;
    float dy = spriteSize.y / h;

    // TODO Normalize sprite size (0.0-1.0)
    // vec2 unitSpriteSize = spriteSize / atlasSize;

    // Figure out the atlas cols
    float cols = w / spriteSize.x;

    // From linear index to row/col pair
    float col = mod(spriteIndex, cols);
    float row = floor(spriteIndex / cols);

    // Finally to UV texture coordinates
    vec2 uv = vec2(
        dx * vcoord.x + col * dx,
        // Flip Y axis
        1.0 - dy - row * dy + dy * vcoord.y
    );

    gl_FragColor = texture2D(atlas, uv);

    // Discard the transparent color
    if (gl_FragColor.a == 0.0) {
      discard;
    }
}
|]


{-  Render atlas animations. It assumes that the animation frames are in one horizontal line.
-}
animatedRectFragmentShader =
    [glsl|
precision mediump float;

uniform sampler2D atlas;
uniform vec2 spriteSize;
uniform vec2 atlasSize;
uniform int spriteIndex;

uniform int frameCount; // Number of frames
uniform float duration; // Total duration
uniform float time;

// Incoming value from vertex shader

varying vec2 vcoord;

void main () {

    // Recast as float
    float frameCount = float(frameCount);
    float spriteIndex = float(spriteIndex);

    // Frame index in time
    float frameIndex = floor(mod(time, duration) / duration * frameCount);

    // Normalize sprite size (0.0-1.0)
    vec2 unitSpriteSize = spriteSize / atlasSize;

    // From linear index (0-...) to actual row
    float row = floor(spriteIndex / (atlasSize.x / spriteSize.x));

    // Finally to UV texture coordinates
    vec2 uv = vec2(
        frameIndex * unitSpriteSize.x + unitSpriteSize.x * vcoord.x,
        // Flip Y axis
        1.0 - unitSpriteSize.y - row * unitSpriteSize.y + unitSpriteSize.y * vcoord.y);

    gl_FragColor = texture2D(atlas, uv);

    // Discard the transparent color
    if (gl_FragColor.a == 0.0) {
      discard;
    }

}
|]
