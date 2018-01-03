module Camera exposing
    ( Camera
    , camera
    , view
    --, moveBy
    , moveTo
    --, follow
    )

{-| This provides a basic camera
-}
import Math.Vector2 as Vector2 exposing (Vec2, vec2)
import Math.Matrix4 as Matrix4 exposing (Mat4)
import Vector2Extra as Vector2


{-|
A camera represents how to render the virtual world. It's essentially a
transformation from virtual game coordinates to pixel coordinates on the screen
-}
type alias Camera =
    { width : Float
    , position : Vec2
    }


{-| A camera that always shows `width` units of your game horizontally.
Well suited for a side-scroller.
-}
camera : Float -> Vec2 -> Camera
camera width position =
    { width = width
    , position = position
    }


{-| Calculate the matrix transformation that represents how to transform the
camera back to the origin. The result of this is used in the vertex shader.
-}
view : Vec2 -> Camera -> Mat4
view viewportSize camera =
    let
        ( w, h ) =
            Vector2.toTuple viewportSize

        ( x, y ) =
            camera.position
                |> Vector2.toTuple

        ( w_, h_ ) =
            ( camera.width * 0.5, camera.width * h / w * 0.5 ) 

        ( l, r, d, u ) =
            ( x - w_, x + w_, y - h_, y + h_ )
    in
        Matrix4.makeOrtho2D l r d u


{-| Move a camera to the given location. In *absolute* coordinates.
-}
moveTo : Vec2 -> Camera -> Camera
moveTo position camera =
    { camera | position = position }
