module Model
    exposing
        ( Model
        , Event(..)
        , GameState(..)
        )

import Keyboard.Extra as Keyboard exposing (Key)
import Math.Vector2 as Vector2 exposing (Vec2, vec2)
import Camera exposing (Camera)
import Objects.Object exposing (Object)
import Dict exposing (Dict)
import Assets exposing (Assets)
import Random

type GameState
    = Loading
    | Playing
    | GameOver



{- Events are used to notify the parent update of significant events
   happening within the game.
-}


type Event
    = PlayerHitObstacle Object
    | PlayerFly Object


type alias Model =
    { objects : Dict Int Object
    , assets : Assets
    , pressedKeys : List Key
    , time : Float
    , viewport : Vec2
    , camera : Camera
    , fixedCamera : Camera
    , state : GameState
    , seed : Random.Seed
    }
