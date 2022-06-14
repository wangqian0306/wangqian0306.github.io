.PHONY: init,deploy,test,update

init:
	npm install hexo-cli -g

deploy:
	hexo clean
	hexo generate
	hexo deploy

test:
	hexo clean
	hexo server

update:
	ncu -u
	npm install