.PHONY: deploy,test

deploy:
	hexo clean
	hexo generate
	hexo deploy

test:
	hexo clean
	hexo server