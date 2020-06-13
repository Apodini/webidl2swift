MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

.PHONY: HelloWorld
HelloWorld:
	cd HelloWorld && \
	    swift build --product HelloWorld --triple wasm32-unknown-wasi -c release -Xlinker -O3

dist/HelloWorld.wasm: HelloWorld
	mkdir -p dist
	cp ./HelloWorld/.build/release/HelloWorld $@

node_modules:
	npm install

build: node_modules dist/HelloWorld.wasm
	cd ./HelloWorld/.build/checkouts/JavaScriptKit/Runtime && npm install && npm run build
	npm install && npm run build
