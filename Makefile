all: index.html
clean:
	rm -f index.html

%.html: %.md
	pandoc $< --self-contained -t revealjs --template=template --slide-level 2 -V theme=beige --css reveal.js/css/theme/beige.css --css prezo.css --css hljs/styles/github-gist.css --html-q-tags -o $@
