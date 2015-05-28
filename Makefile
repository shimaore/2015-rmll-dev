%.html: %.md
	pandoc $< -t revealjs --self-contained --slide-level 2 -V theme=beige --css reveal.js/css/reveal.min.css --css reveal.js/css/theme/beige.css --css prezo.css  -o $@
