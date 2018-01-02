module Objects.Pipe
    exposing
        ( spawn
        , update
        , render
        , columnDistance
        )

{-| Pipe game object implementation.
-}

import Math.Vector2 as Vector2 exposing (Vec2, vec2)
import Math.Vector3 as Vector3 exposing (Vec3, vec3)
import Math.Matrix4 exposing (Mat4)
import WebGL exposing (Entity)
import Assets exposing (Assets)
import Render exposing (Uniform(..))
import Objects.Object as Object exposing (Object, Category(..), Pipe)
import Model exposing (Model)
import Random


columnDistance = 
    100


maxDistanceFromCamera = 
    90


spriteSize =
    vec2 32 128


collisionSize =
    vec2 26 128


pipesAsset =
    Assets.pipes


pipes =
    Assets.texture pipesAsset.name


spawn : Assets -> Int -> Vec2 -> Bool -> Object
spawn assets id position isUp =
    let
        category =
            PipeCategory
                { atlas = (pipes assets)
                , isUp = isUp
                }
    in
        { category = category
        , id = id
        , name = "Pipe"
        , position = position
        , collisionSize = collisionSize
        }


-- MOVEMENT


{-| Called on every update cycle by the game engine
-}
update : Model -> Random.Seed -> Object -> Pipe -> ( Object, Random.Seed )
update { camera } seed object pipe =
    let
        ( x, y ) =
            Vector2.toTuple object.position

        ( cameraX, _ ) =
            Vector2.toTuple camera.position
    in  
        -- Check if pipe went offscreen
        if cameraX - x > maxDistanceFromCamera then
            let
                ( offset, newSeed ) = 
                    Random.step offsetGenerator seed
            in
                ( { object
                    | position = vec2 ( x + columnDistance + maxDistanceFromCamera ) ( y + offset )
                }, newSeed )
        else
            ( object, seed )


offsetGenerator : Random.Generator Float
offsetGenerator =
    Random.float -22 22


-- RENDERING


render : Float -> Mat4 -> Object -> Pipe -> Entity
render time cameraProjection { position } { atlas, isUp } =
    let
        ( x, y ) =
            Vector2.toTuple position

        spriteIndex =
            if isUp then 1 else 0
    in
        Render.renderSprite
            cameraProjection
            (vec3 x y Object.zPosition)
            atlas
            spriteSize
            spriteIndex
