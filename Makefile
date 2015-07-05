all: index.html
clean:
	rm -f index.html

%.html: %.md
	pandoc $< --self-contained -t revealjs --template=template --slide-level 2 -V theme=beige --css reveal.js/css/theme/beige.css --css prezo.css --css hljs/styles/github-gist.css --html-q-tags -o $@
%.pdf: %.md
	pandoc $< --self-contained -o $@

publish:
	git checkout gh-pages
	git merge master
	make clean all
	git add index.html
	git commit -m build
	git push
	git checkout master
