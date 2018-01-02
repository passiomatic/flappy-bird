all: build

build:
	elm-make src/Main.elm --output dist/elm.js

dist: build
	cp -R images dist/
	cp index.html dist/index.html

run:
	elm-reactor
