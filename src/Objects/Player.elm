module Objects.Player
    exposing
        ( spawn
        , update
        , render
        )

import Keyboard.Extra as Keyboard exposing (Key)
import WebGL exposing (Entity)
import WebGL.Texture as Texture exposing (Texture)
import Math.Vector2 as Vector2 exposing (Vec2, vec2)
import Math.Vector3 as Vector3 exposing (Vec3, vec3)
import Vector2Extra as Vector2
import Math.Matrix4 exposing (Mat4)
import Render exposing (Uniform(..))
import Objects.Object as Object exposing (Object, Category(..), Player)
import Assets exposing (Assets)
import Model exposing (Model)


flyFrames =
    ( 0, 4, 0.4 )


deadFrames =
    ( 5, 1, 1 )


flySpeed =
    30


spriteSize =
    vec2 32 32


collisionSize =
    vec2 15 12


showOutline = 
    False


spawn : Assets -> Vec2 -> Object
spawn assets position =
    let
        birdAsset =
            Assets.bird

        atlas =
            Assets.texture birdAsset.name assets

        category =
            PlayerCategory
                { atlas = atlas
                , velocity = vec2 flySpeed 0
                , isDead = False
                }
    in
        { category = category
        , id = Object.playerId
        , name = "Player"
        , position = position
        , collisionSize = collisionSize
        }



-- MOVEMENT


jumpKey = 
    Keyboard.CharW


gravity =
    vec2 0 -4


nextVelocity : Player -> List Key -> Vec2
nextVelocity player keys = 
    let
        direction = 
            if List.member jumpKey keys then
                vec2 0 18
            else
                vec2 0 0
    in
        if player.isDead then
            -- Don't move
            Vector2.zero
        else
            Vector2.add player.velocity direction
                |> Vector2.add gravity


{-| Called on every update cycle by the game engine
-}
update : Float -> Model -> Object -> Player -> Object
update dt { pressedKeys } object player =
    let
        newPlayer =
            { player
                | velocity = nextVelocity player pressedKeys
            }

        -- Calculate next player position, limiting 
        --   vertical position to viewport height
        ( x, y ) =
            Vector2.add object.position (Vector2.scale dt newPlayer.velocity)
                |> Vector2.toTuple

        newObject = 
            { object | position = vec2 x ( min y 260 ) }
    in
        { newObject | category = PlayerCategory newPlayer }



-- RENDERING


render : Float -> Mat4 -> Object -> Player -> Entity
render time cameraProj { position } ({ atlas, velocity } as player) =
    let
        ( x, y ) =
            Vector2.toTuple position

        ( _, vy ) = 
            Vector2.toTuple velocity

        playerPosition =
            vec3 x y Object.zPosition

        ( spriteIndex, frameCount, duration ) =
            if player.isDead then
                deadFrames
            else
                flyFrames

        ( atlasW, atlasH ) =
            Texture.size atlas

        rotation = 
            if player.isDead then 
                0
            else if vy > 0 then 
                0.7 
            else 
                -0.7

        animatedUniforms =
            { transform = Render.makeTransform playerPosition spriteSize rotation ( 0.5, 0.5 )
            , cameraProj = cameraProj
            , atlas = atlas
            , frameCount = frameCount
            , spriteIndex = spriteIndex
            , duration = duration
            , time = time
            , spriteSize = spriteSize
            , atlasSize = Vector2.fromInt atlasW atlasH
            }

        outlinedUniforms =
            { transform = Render.makeTransform playerPosition collisionSize 0 ( 0.5, 0.5 )
            , cameraProj = cameraProj
            , color = vec3 0 1.0 0            
            }            
    in
        if showOutline then 
            Render.toEntity (OutlinedRect outlinedUniforms)
        else 
            Render.toEntity (AnimatedRect animatedUniforms)


