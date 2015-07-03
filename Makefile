all: index.html

%.html: %.md
	pandoc $< --self-contained -t revealjs --template=template --slide-level 2 -V theme=beige --css reveal.js/css/theme/beige.css --css prezo.css --css reveal.js/lib/css/zenburn.css --html-q-tags -o $@
