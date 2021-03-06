module Render exposing
    ( Vertex
    -- , unitSquareMesh
    , makeTransform
    , renderSprite
    , toEntity
    , toHtml
    , Uniform(..)
    , TexturedRectUniform
    , AnimatedRectUniform
    , ColoredRectUniform
    )

{-| WebGL rendering types and helpers
-}

import Math.Matrix4 as Matrix4 exposing (Mat4)
import Math.Vector2 as Vector2 exposing (Vec2, vec2)
import Math.Vector3 as Vector3 exposing (Vec3, vec3)
import Vector3Extra as Vector3
import Vector2Extra as Vector2

import WebGL exposing (Mesh, Entity, Option)
import WebGL.Texture as Texture exposing (Texture)
import WebGL.Settings.Blend as Blend
import WebGL.Settings.DepthTest as DepthTest

import Shaders

import Html exposing (Html, Attribute)
import Html.Attributes as Attr


{-| Alias for a 2D vector. Needs to be in a record because it will be passed as an
attribute to the vertex shader
-}
type alias Vertex =
    { position : Vec2 }


{-| A filled square with corners (0, 0), (1, 1)
-}
unitSquareMesh : Mesh Vertex
unitSquareMesh =
    WebGL.triangles
        [ ( Vertex (vec2 0 0)
          , Vertex (vec2 0 1)
          , Vertex (vec2 1 0)
          )
        , ( Vertex (vec2 0 1)
          , Vertex (vec2 1 0)
          , Vertex (vec2 1 1)
          )
        ]

{-| An outlined square with corners (0, 0), (1, 1)
-}
unitOutlineMesh : Mesh Vertex
unitOutlineMesh = 
    WebGL.lineLoop 
        [ Vertex (vec2 0 0)
        , Vertex (vec2 0 1)
        , Vertex (vec2 1 1)
        , Vertex (vec2 1 0)
        ]


{-| Create a transformation matrix usually passed to the vertex shader.

    makeTransform (vec3 x, y, z)  (vec2 w, h ) rotation (vec2 px, py )
-}
makeTransform : Vec3 -> Vec2 -> Float -> (Float, Float) -> Mat4
makeTransform position size rotation (pivotX, pivotY) =
    let
        transform =
            Matrix4.makeTranslate position

        rotation_ =
            Matrix4.makeRotate rotation (vec3 0 0 1)

        (w, h) =
            Vector2.toTuple size

        scale =
            Matrix4.makeScale (vec3 w h 1)

        pivot =
            Matrix4.makeTranslate (vec3 -pivotX -pivotY 0)
    in
        (Matrix4.mul (Matrix4.mul (Matrix4.mul transform rotation_) scale) pivot)


-- WEBGL RENDERING

type alias TransformationUniform a =
    { a
    | transform : Mat4
    , cameraProj : Mat4
    }

type alias TexturedRectUniform =
    TransformationUniform
        { atlas : Texture
        , atlasSize : Vec2
        , spriteSize : Vec2
        , spriteIndex : Int
        }


type alias AnimatedRectUniform =
    TransformationUniform
        { atlas : Texture
        , atlasSize : Vec2
        , spriteSize : Vec2
        , spriteIndex : Int
        , frameCount : Int
        , duration : Float
        , time : Float
        }


type alias ColoredRectUniform =
    TransformationUniform
        { color : Vec3
        }


type alias OutlinedRectUniform =
    TransformationUniform
        { color : Vec3
        }


type Uniform
    = ColoredRect ColoredRectUniform
    | TexturedRect TexturedRectUniform
    | AnimatedRect AnimatedRectUniform
    | OutlinedRect OutlinedRectUniform


entitySettings =
    [ DepthTest.default
    , Blend.add Blend.one Blend.oneMinusSrcAlpha
    ]


{-| Render a unanimated sprite at given position
-}
renderSprite : Mat4 -> Vec3 -> Texture -> Vec2 -> Int -> Entity
renderSprite cameraProj position atlas spriteSize spriteIndex =

    let
        ( atlasW, atlasH ) =
            Texture.size atlas

        uniforms =
            { transform = makeTransform position spriteSize 0 ( 0.5, 0.5 )
            , cameraProj = cameraProj
            , atlas = atlas
            , atlasSize = Vector2.fromInt atlasW atlasH
            , spriteSize = spriteSize
            , spriteIndex = spriteIndex
            --, color = vec3 1.0 0 0            
            }
    in
        toEntity (TexturedRect uniforms)
        -- toEntity (OutlinedRect uniforms)        


toEntity: Uniform -> Entity
toEntity uniforms =
    case uniforms of
        ColoredRect uniforms ->
            coloredRectEntity uniforms

        TexturedRect uniforms ->
            texturedRectEntity uniforms

        AnimatedRect uniforms ->
            animatedRectEntity uniforms

        OutlinedRect uniforms ->
            outlinedRectEntity uniforms


coloredRectEntity: (ColoredRectUniform -> Entity)
coloredRectEntity =
    WebGL.entityWith
        entitySettings
        Shaders.vertexShader
        Shaders.coloredRectFragmentShader
        unitSquareMesh


texturedRectEntity : (TexturedRectUniform -> Entity)
texturedRectEntity =
    WebGL.entityWith
        entitySettings
        Shaders.vertexShader
        Shaders.texturedRectFragmentShader
        unitSquareMesh


animatedRectEntity : (AnimatedRectUniform -> Entity)
animatedRectEntity =
    WebGL.entityWith
        entitySettings
        Shaders.vertexShader
        Shaders.animatedRectFragmentShader
        unitSquareMesh


outlinedRectEntity : (OutlinedRectUniform -> Entity)
outlinedRectEntity =
    WebGL.entityWith
        entitySettings
        Shaders.vertexShader
        Shaders.coloredRectFragmentShader
        unitOutlineMesh


-- WebGL rendering options, see:
--  http://package.elm-lang.org/packages/elm-community/webgl/2.0.3/WebGL#Option
renderOptions : List Option
renderOptions =
    [ WebGL.alpha False
    , WebGL.depth 1
    --, WebGL.clearColor 0 0 0 0
    ]


toHtml : ( Int, Int ) -> List Entity -> Html msg
toHtml ( w, h ) entities =
    WebGL.toHtmlWith
        renderOptions
        [ Attr.width w, Attr.height h ]
        entities
