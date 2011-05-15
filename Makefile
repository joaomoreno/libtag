all: docs

docs: lib/*.coffee
	docco lib/*.coffee

js: lib/*.coffee
	coffee -o js/ -bc lib/*.coffee

