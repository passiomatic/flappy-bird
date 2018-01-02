module Messages exposing (..)

import Window exposing (Size)
import Keyboard.Extra as Keyboard
import Assets

type Msg
    = ScreenSize Window.Size
    | Tick Float
    | KeyMsg Keyboard.Msg
    | AssetMsg Assets.Msg
