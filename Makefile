# Makefile

# generated vars ############################################################
PY=python
PELICAN=pelican
PELICANOPTS=

BASEDIR=$(CURDIR)
INPUTDIR=$(BASEDIR)/content
OUTPUTDIR=$(BASEDIR)/output
CONFFILE=$(BASEDIR)/pelicanconf.py
PUBLISHCONF=$(BASEDIR)/publishconf.py

FTP_HOST=localhost
FTP_USER=anonymous
FTP_TARGET_DIR=/

SSH_HOST=ec2-54-228-160-69.eu-west-1.compute.amazonaws.com
SSH_PORT=22
SSH_USER=ubuntu
SSH_TARGET_DIR=/var/www

S3_BUCKET=my_s3_bucket

DROPBOX_DIR=~/Dropbox/Public/


# other vars ################################################################
GROOVY=groovy
JAVA=java
SCRIPTS=$(BASEDIR)/bin
Y2H=$(SCRIPTS)/yam2html
EPI=$(SCRIPTS)/enpelicanise.sh


# generated targets #########################################################
help:
	@echo 'Makefile for a pelican Web site                                        '
	@echo '                                                                       '
	@echo 'Usage:                                                                 '
	@echo '   make html                        (re)generate the web site          '
	@echo '   make clean                       remove the generated files         '
	@echo '   make regenerate                  regenerate files upon modification '
	@echo '   make publish                     generate using production settings '
	@echo '   make serve                       serve site at http://localhost:8000'
	@echo '   make devserver                   start/restart develop_server.sh    '
	@echo '   make stopserver                  stop local server                  '
	@echo '   ec2-upload                       upload the web site via rsync+ssh  '
	@echo '   pigate-upload                    upload the web site via rsync+ssh  '
	@echo '                                                                       '
	@echo '   check                            check prerequisites                '
	@echo '   prepare                          regenerate the sources             '
	@echo '   google-site-verify               install web tools verification     '
	@echo '   robots                           create output/robots.txt           '
	@echo '   favicon                          create output/favicon.ico          '
	@echo '                                                                       '
	@echo '   minify                           compress the output html           '
	@echo '                                                                       '


html: check clean prepare $(OUTPUTDIR)/index.html google-site-verify robots favicon

$(OUTPUTDIR)/%.html:
	$(PELICAN) $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)

clean:
	[ ! -d $(OUTPUTDIR) ] || find $(OUTPUTDIR) -mindepth 1 -delete

regenerate: clean
	$(PELICAN) -r $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)

serve:
	cd $(OUTPUTDIR) && $(PY) -m pelican.server

devserver:
	$(BASEDIR)/develop_server.sh restart

stopserver:
	kill -9 `cat pelican.pid`
	kill -9 `cat srv.pid`
	@echo 'Stopped Pelican and SimpleHTTPServer processes running in background.'

publish:
	$(PELICAN) $(INPUTDIR) -o $(OUTPUTDIR) -s $(PUBLISHCONF) $(PELICANOPTS)

# not using publish conf at present:
#upload: publish
ec2upload:
	rsync -e "ssh -p $(SSH_PORT) -i $${EC2_PEM}" \
          -P -rvz --delete $(OUTPUTDIR)/ $(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR) --cvs-exclude
gateupload:
	rsync -e "ssh -p $(SSH_PORT)" \
          -P -rvz --delete --delete-excluded $(OUTPUTDIR)/ $${GE1_USER}@gate.ac.uk:/data/herd/pi.gate.ac.uk/html --cvs-exclude --exclude '.htaccess' --exclude '.htpasswd'

.PHONY: html help clean regenerate serve devserver publish upload


# other targets #############################################################
# use this one if we need groovy:
#check: ; @which $(JAVA) >/dev/null && which $(GROOVY) >/dev/null || \
#	echo 'oops! no java and/or no groovy in your path? try apt-get install ...?'
check: ; @which $(JAVA) >/dev/null >/dev/null || \
	echo 'oops! no java in your path? try apt-get install ...?'

# this does regeneration from GATEwiki sources and the like
prepare:
	cd $(INPUTDIR) && $(Y2H) -na && $(EPI) `ls *.html`
	cd $(INPUTDIR)/basics && touch basics.yam && \
          $(Y2H) -Fna && cp basics.html ../pages
	cp $(INPUTDIR)/piroomba/piroomba.html $(INPUTDIR)/pages
	cd $(INPUTDIR)/pages && $(Y2H) -na && \
          $(EPI) about.html basics.html schools.html notipi.html legocases.html hardware.html && \
          $(EPI) -n piroomba.html

google-site-verify:
	echo 'google-site-verification: google2bff225e702ae7d8.html' >output/google2bff225e702ae7d8.html

robots:
	cp robots.txt output/robots.txt
favicon:
	cp content/images/favicon.ico output

# compress html using http://code.google.com/p/htmlcompressor/
minify:
	java -jar bin/htmlcompressor-1.5.3.jar --preserve-line-breaks -r output/ -o compressed-output/
	cd compressed-output && for f in `find . -name '*.html'`; do mv $$f ../output/$${f}; done
	rm -rf compressed-output

.PHONY: check prepare google-site-verify robots favicon minify
