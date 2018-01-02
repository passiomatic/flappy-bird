module Objects.Object
    exposing
        ( Object
        , Category(..)
        , Pipe
        , Player
--      , move
        , colliding
        , zPosition
--      , player
        , playerId
        )

import Math.Vector2 as Vector2 exposing (Vec2, vec2)
import WebGL.Texture as Texture exposing (Texture)
--import Dict exposing (Dict)


{-| The main game object type. See individual file (e.g. Player.elm)
for actual implementation
-}
type Category
    = PipeCategory Pipe
    | PlayerCategory Player


zPosition =
    0.35


type alias Pipe =
    TexturedObject
        { isUp : Bool
        }


type alias Player =
    TexturedObject
        { velocity : Vec2
        , isDead :
            Bool
        }


{-| A generic object in the level
-}
type alias Object =
    { category : Category
    , id : Int
    , name : String
    , position : Vec2
    , collisionSize : Vec2
    }


{-| Object with an associated texture atlas with
potentially multiple appearance
-}
type alias TexturedObject a =
    { a | atlas : Texture }


{-| Convenience type alias used during collision detection
-}
type alias Rectangle =
    { x : Float
    , y : Float
    , w : Float
    , h : Float
    }



-- MISC


playerId =
    -- Hardcoded id to grab the player object later
    0


-- player : Dict Int Object -> Maybe Object
-- player objects =
--     Dict.get playerId objects



-- MOVEMENT


{- Move object with the given velocity vector
-}
-- move : Float -> Vec2 -> Object -> Object
-- move dt velocity ({ position } as object) =
--     { object
--         | position =
--             Vector2.add position (Vector2.scale dt velocity)
--     }



-- COLLISION

{-| Return the game objects colliding with target object -}
colliding : List Object -> Object -> List Object
colliding objects targetObject =
    let
        targetRect =
            toRectangle targetObject
    in
        objects
            -- Exclude itself
            |> List.filter (\object -> object.id /= targetObject.id)
            |> List.filter (isColliding targetRect)


isColliding : Rectangle -> Object -> Bool
isColliding rect1 object =
    let
        rect2 =
            toRectangle object
    in
        rect1.x < rect2.x + rect2.w && 
        rect1.x + rect1.w > rect2.x &&
        rect1.y < rect2.y + rect2.h && 
        rect1.h + rect1.y > rect2.y


toRectangle : Object -> Rectangle
toRectangle object =
    let
        ( cx, cy ) =
            Vector2.toTuple object.position

        ( w, h ) =
            Vector2.toTuple object.collisionSize

        startingPoint centerPoint length =
            centerPoint - (length / 2)

        x =
            startingPoint cx w

        y =
            startingPoint cy h
    in
        { x = x, y = y, w = w, h = h }
