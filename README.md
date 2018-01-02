# Flappy Bird in Elm

This is a remake of the popular [Flappy Bird][fb] game, this time written in Elm and WebGL.

[Try it online][home].

## Run locally

Clone the repo and run:

    elm-package install

Elm will ask for confirmation and download all the necessary packages. Then run:

    elm-reactor

and point your browser to `http://localhost:8000/index.html`.  

## Game art credits

Graphics are copyright of Dong Nguyen, the original Flappy Bird author.

## Code credits

Flappy Bird contains portions of:

* Florian Zinggeler's [Game.TwoD][6] and [Game.Resources][8]
* Nicolas Fernandez's [Collision2D][7]

[6]: http://package.elm-lang.org/packages/Zinggi/elm-2d-game/latest/
[7]: http://package.elm-lang.org/packages/burabure/elm-collision/latest
[8]: http://package.elm-lang.org/packages/Zinggi/elm-game-resources/latest
[home]: http://lab.passiomatic.com/flappy-bird/
[fb]: https://en.wikipedia.org/wiki/Flappy_Bird
