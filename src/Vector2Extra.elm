module Vector2Extra exposing (zero, snap, fromInt)

import Keyboard.Extra as Keyboard exposing (Direction(..))
import Math.Vector2 as Vector2 exposing (Vec2, vec2)


zero =
    vec2 0 0


fromInt : Int -> Int -> Vec2
fromInt x y =
    vec2 (toFloat x) (toFloat y)


{-| Snap value to nearest integer value
-}
snap : Vec2 -> Vec2
snap value =
    let
        (x, y) =
            Vector2.toTuple value
    in
        vec2 (rounder x) (rounder y)


rounder =
    floor >> toFloat
