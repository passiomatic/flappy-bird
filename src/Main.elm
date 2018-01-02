module Main exposing (..)

import Html exposing (Html, text)
import Task
import AnimationFrame
import Window
import Keyboard.Extra as Keyboard
import Math.Vector2 as Vector2 exposing (Vec2, vec2)
import Vector2Extra as Vector2
import Render
import Scene
import Camera exposing (Camera)
import Dict exposing (Dict)
import Assets exposing (Assets)
import Model exposing (Model, GameState(..), Event(..))
import Messages exposing (Msg(..))
import Random


type alias Flags =
  { value : Int
  }


viewportSize =
    vec2 144 256


vieportScale =
    3.0


camera =
    Camera.camera viewportSize Vector2.zero


init : Flags -> ( Model, Cmd Msg )
init { value } =
    initialModel (Random.initialSeed value)
    ! [ getScreenSize
    , Cmd.map AssetMsg (Assets.loadAssets Assets.all)
    ]


initialModel : Random.Seed -> Model
initialModel seed =
    { objects = Dict.empty
    , assets = Dict.empty
    , pressedKeys = []
    , time = 0
    , viewport = viewportSize
    , camera = camera
    , fixedCamera = camera
    , state = Loading
    , seed = seed
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScreenSize { width, height } ->
            --{ model | viewport = Vector2.fromInt width height } ! []
            model ! []

        Tick dt ->
            tick dt model ! []

        AssetMsg msg ->
            let
                newAssets =
                    Assets.update msg model.assets
            in
                if Assets.isLoadingComplete Assets.all newAssets then
                    ({ model
                        | assets = newAssets
                     }
                        |> startGame
                    )
                        ! []
                else
                    { model
                        | assets = newAssets
                    }
                        ! []

        KeyMsg keyMsg ->
            { model
                | pressedKeys = Keyboard.update keyMsg model.pressedKeys
            }
                ! []


startGame : Model -> Model
startGame model =
    let
        objects =
            Scene.spawnObjects model.assets
    in
        { model
            | objects = objects
            , state = Playing
        }


tick : Float -> Model -> Model
tick dt ({ camera } as model) =
    let
        time =
            dt + model.time

        ( objects, events, seed ) =
            Scene.update dt model

        applyEvent event model =
            case event of
                PlayerHitObstacle playerObject ->
                    { model
                        | state = GameOver
                        , objects = Scene.addObject playerObject objects
                        , time = time
                        , seed = seed                        
                    }  

                PlayerFly playerObject ->
                    let
                        newCamera =
                            updateCamera playerObject.position camera
                    in
                        { model
                            | objects = Scene.addObject playerObject objects
                            , time = time
                            , seed = seed
                            , camera = newCamera
                        }
    in
        List.foldl applyEvent model events


{-| Adjust camera to the resolved target position
-}
updateCamera : Vec2 -> Camera -> Camera
updateCamera position camera =
    let
        ( x, _ ) =
            Vector2.toTuple position

        -- Keep camera slightly ahead of target
        targetPosition =
            vec2 (x + 40) 140
    in
        Camera.moveTo targetPosition camera



-- VIEW


view : Model -> Html msg
view model =
    case model.state of
        Loading ->
            renderLoading model

        Playing ->
            renderPlaying model

        GameOver ->
            -- TODO
            renderPlaying model


renderPlaying : Model -> Html msg
renderPlaying model =
    let
        scene =
            Scene.render model

        -- Calculate scaled WebGL canvas size
        ( w, h ) =
            Vector2.scale vieportScale model.viewport
                |> Vector2.toTuple
    in
        Render.toHtml ( floor w, floor h ) scene


renderLoading : Model -> Html msg
renderLoading _ =
    text "Loading assets..."


getScreenSize : Cmd Msg
getScreenSize =
    Task.perform ScreenSize (Window.size)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ -- Window.resizes ScreenSize
        Sub.map KeyMsg Keyboard.subscriptions
        , AnimationFrame.diffs ((\dt -> dt / 1000) >> Tick)
        ]


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
