.PHONY: init,deploy,test

init:
	npm install hexo-cli -g

deploy:
	hexo clean
	hexo generate
	hexo deploy

test:
	hexo clean
	hexo server