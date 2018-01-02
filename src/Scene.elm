module Scene
    exposing
        ( spawnObjects
        , addObject
        , update
        , render
        --, resolveCollisions
        )

{-| Scene creation, updating and rendering functions
-}

import Assets exposing (Assets)
import Math.Vector2 as Vector2 exposing (Vec2, vec2)
import Math.Vector3 as Vector3 exposing (Vec3, vec3)
import Math.Matrix4 exposing (Mat4)
import WebGL exposing (Entity)
import Render exposing (Uniform(..))
import Objects.Object as Object exposing (Object, Player, Pipe, Category(..))
import Objects.Player as Player
import Objects.Pipe as Pipe
import Dict exposing (Dict)
import Assets
import Model exposing (Model, Event(..))
import Camera
import Random


-- CREATION


spawnObjects : Assets -> Dict Int Object
spawnObjects assets =
    let
        objects =
            [ ( Object.playerId, Player.spawn assets (vec2 0 160) )
              -- Generate only 2 columns and move them
              --   ahead of player when they go offscreen
            , ( 1, Pipe.spawn assets 1 (vec2 Pipe.columnDistance 260) False )
            , ( 2, Pipe.spawn assets 2 (vec2 Pipe.columnDistance 64) True )
            , ( 3, Pipe.spawn assets 3 (vec2 ( Pipe.columnDistance * 2 ) 260) False )
            , ( 4, Pipe.spawn assets 4 (vec2 ( Pipe.columnDistance * 2 ) 64) True )
            ]
    in
        Dict.fromList objects


addObject : Object -> Dict Int Object -> Dict Int Object
addObject object objects =
    Dict.insert object.id object objects



-- UPDATING


{-| Update all the scene objects
-}
update : Float -> Model -> ( Dict Int Object, List Event, Random.Seed )
update dt model =
    let
        updater : Int -> Object -> ( Dict Int Object, Random.Seed ) -> ( Dict Int Object, Random.Seed ) 
        updater id object ( objects, seed ) =
            case object.category of
                PlayerCategory player ->
                    let
                        newObject = 
                            Player.update dt model object player                        
                    in                                            
                        ( addObject newObject objects, seed ) 

                PipeCategory pipe ->
                    let
                        ( newObject, newSeed ) = 
                            Pipe.update model seed object pipe                        
                    in                                            
                        ( addObject newObject objects, newSeed ) 

        ( newObjects, newSeed ) = 
            Dict.foldl updater ( Dict.empty, model.seed ) model.objects

        -- Resolve player collisions and turn into events
        resolver : Int -> Object -> List Event -> List Event
        resolver id object events =
            case object.category of
                PlayerCategory player ->
                    events ++ (playerCollisions object player newObjects)

                _ ->
                    events

        events =
            Dict.foldl resolver [] newObjects

    in
        ( newObjects, events, newSeed ) 


{-| Check player object against the others
-}
playerCollisions : Object -> Player -> Dict Int Object -> List Event
playerCollisions playerObject player objects =
    let
        collidingObjects =
            Object.colliding (Dict.values objects) playerObject

        makeHitEvent _ =
            let
                newPlayerObject =
                    { playerObject | category = 
                        PlayerCategory { player | isDead = True } 
                    }
            in
                PlayerHitObstacle newPlayerObject
    in
        if (playerObject.position |> Vector2.toTuple |> Tuple.second) <= 62 then                
            -- Hit ground 
            [ makeHitEvent () ]
        else if List.isEmpty collidingObjects then
            -- No collisions, keep flying birdie!
            [ PlayerFly playerObject ]
        else
            -- Hit pipe
            List.map makeHitEvent collidingObjects



-- RENDERING


fontAsset =
    Assets.font


render : Model -> List Entity
render ({ assets, time, viewport, objects, camera, fixedCamera } as model) =
    let
        cameraProjection =
            Camera.view viewport camera

        fixedCameraProjection =
            Camera.view viewport fixedCamera
    in
        renderBackground assets fixedCameraProjection
            :: renderGround time assets fixedCameraProjection
            :: renderObjects time cameraProjection objects



-- ++ Text.renderText time fixedCameraProj (vec3 -30 -150 0.8) atlas "42/99"


backgroundAsset =
    Assets.background


background =
    Assets.texture backgroundAsset.name


backgroundSize =
    vec2 144 256


renderBackground : Assets -> Mat4 -> Entity
renderBackground assets cameraProjection =
    Render.renderSprite
        cameraProjection
        (vec3 0 0 0.1)
        (background assets)
        backgroundSize
        0


groundAsset =
    Assets.ground


ground =
    Assets.texture groundAsset.name


groundSize =
    vec2 144 56


renderGround : Float -> Assets -> Mat4 -> Entity
renderGround time assets cameraProjection =
    Render.renderSprite
        cameraProjection
        (vec3 0 -100 0.4)
        (ground assets)
        groundSize
        0


renderObjects : Float -> Mat4 -> Dict Int Object -> List Entity
renderObjects time cameraProjection objects =
    let
        renderer : Int -> Object -> (List Entity -> List Entity)
        renderer id object =
            case object.category of
                PlayerCategory player ->
                    (::) (Player.render time cameraProjection object player)

                PipeCategory pipe ->
                    (::) (Pipe.render time cameraProjection object pipe)
    in
        Dict.foldl renderer [] objects
