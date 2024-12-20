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
SSH_HOST=some.ip.address
SSH_PORT=22
SSH_USER=ubuntu
SSH_TARGET_DIR=/var/www

# other vars ################################################################
GROOVY=groovy
JAVA=java
SCRIPTS=$(BASEDIR)/bin
Y2H=JAVA_OPTS=-Dfile.encoding=UTF-8 $(SCRIPTS)/yam2html
PDC=pandoc -S -t html5 --template=$(SCRIPTS)/html.html5 --data-dir=content --standalone
RUNJINJA=$(SCRIPTS)/run-jinja.py
EPI=$(SCRIPTS)/enpelicanise.sh
GETMETAS=$(SCRIPTS)/get-pdc-metas.sh
FIXIMGS=$(SCRIPTS)/fix-image-sizes.groovy
PICPAGE=$(SCRIPTS)/picpage.sh

# generated targets #########################################################
help:
	@echo 'Makefile for Yammerated Pelican sites (e.g. pi.gate.ac.uk)    '
	@echo '                                                              '
	@echo 'Usage:                                                        '
	@echo '- to regenerate do "make html"                                '
	@echo '- to add new posts, just put a new text in content/           '
	@echo '- to add a new pages, put a new text in content/pages and add '
	@echo '  to the list STANDARD_PAGES in the Makefile                  '
	@echo '- to upload, do "GE1_USER=my-account-name make gateupload"    '
	@echo '- to upload draft, do "EC2_PEM=my-id.pem make ec2upload"      '
	@echo '- to upload to S3, do "make s3upload"                         '
	@echo '- to create post, do "SLUG=my-slug make post"                 '
	@echo '                                                              '
	@echo 'More details of targets (or see README.html):                 '
	@echo '   html                  (re)generate the web site            '
	@echo '   clean                 remove the generated files           '
	@echo '   regenerate            regenerate files upon modification   '
	@echo '   publish               generate using production settings   '
	@echo '   serve                 serve site at http://localhost:8000  '
	@echo '   devserver             start/restart develop_server.sh      '
	@echo '   stopserver            stop local server                    '
	@echo '   ec2upload             upload the web site via rsync+ssh    '
	@echo '   gateupload            upload the web site via rsync+ssh    '
	@echo '   s3upload              upload the web site to S3 via s3cmd  '
	@echo '                         (files listed to s3upload-files.txt) '
	@echo '   s3upload-simple       sync the web site to S3 via s3cmd    '
	@echo '                                                              '
	@echo '   prepare               regenerate the sources               '
	@echo '   finalise              fixup the generated output           '
	@echo '   google-site-verify    install web tools verification       '
	@echo '   robots                create output/robots.txt             '
	@echo '   favicon               create output/favicon.ico            '
	@echo '                                                              '
	@echo '   minify                compress the output html             '
	@echo '   fix-image-sizes       add missing dimensions to img tags   '
	@echo '   archive               make an archive copy of .htmls       '
	@echo '                         (warning: interacts with s3upload!)  '
	@echo '   archive-diff          diff the archive against the output  '
	@echo '   fix-rss-feeds         absolutise the URLs in the RSS feeds '
	@echo '                                                              '
	@echo '   post                  create files for a new YAM post      '
	@echo '   pdc-post              create files for a new Pandoc post   '
	@echo '   draft                 create files for a new draft YAM post'
	@echo '                                                              '
	@echo '   checklinks/linchecker check links locally                  '
	@echo '   s3list                list all the bucket .htmls           '
	@echo '   picpage               create a page containing all images  '
	@echo '                                                              '

# local stuff
include Makefile.local

# standard pelican stuff
html: clean prepare $(OUTPUTDIR)/index.html \
        finalise google-site-verify robots favicon
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
	@echo 'Stopped Pelican and SimpleHTTPServer processes in background.'
publish:
	$(PELICAN) $(INPUTDIR) -o $(OUTPUTDIR) -s $(PUBLISHCONF) $(PELICANOPTS)

# (not using publish conf at present: ...upload: publish)
ec2upload: fix-rss-feeds minify
	rsync -e "ssh -p $(SSH_PORT) -i $${EC2_PEM}" -hP -rvz --delete \
          --delete-excluded \
          $(OUTPUTDIR)/ $(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR) \
          --cvs-exclude --exclude '.htaccess' --exclude '.htpasswd'
gateupload: fix-rss-feeds minify
	rsync -e "ssh -p $(SSH_PORT)" -hP -rvz --delete --delete-excluded \
          $(OUTPUTDIR)/ $${GE1_USER}@gate.ac.uk:/data/herd/$(SITE)/html \
          --cvs-exclude --exclude '.htaccess' --exclude '.htpasswd'
s3upload: fix-rss-feeds minify
	s3cmd sync -r output/ --exclude '.htaccess' --exclude='.htpasswd' \
          --progress --delete-removed s3://$(SITE)/ \
          |tee /tmp/s3upload-files.txt; \
          cat /tmp/s3upload-files.txt |$(SCRIPTS)/get-upload-list.sh > s3upload-files.txt
	grep 'index.html$$' s3upload-files.txt |sed 's,index.html$$,,' \
          >>s3upload-files.txt
s3upload-simple:
	s3cmd sync -r output/ --exclude '.htaccess' --exclude='.htpasswd' \
          --progress --delete-removed s3://$(SITE)/

# for each .yam in content/ fix missing image sizes in the .html and do diff
fix-image-sizes:
	@YAMS=`find $(INPUTDIR) -name '*.yam'`; \
        for f in $$YAMS; do \
          echo "fixing $${f}..."; \
          BASE=`echo $$f |sed 's,\.yam$$,,'`; HTML=$${BASE}.html; \
          $(Y2H) $${f} >/dev/null; \
          $(FIXIMGS) $${HTML} >/dev/null; \
          [ -f $${HTML}-new.html ] && echo diffing $${HTML}* && \
            diff $${HTML} $${HTML}-new.html |egrep '<img|src=|width|height'; \
          rm -f $${HTML}-new.html; \
          echo; \
        done
	cd $(OUTPUTDIR); sed 's, src="/, src="./,g' index.html >xindex.html; \
        HTML=xindex.html; $(FIXIMGS) $${HTML} >/dev/null; \
        [ -f $${HTML}-new.html ] && echo diffing $${HTML}* && \
          diff $${HTML} $${HTML}-new.html |egrep 'image|width|height'; \
        rm -f $${HTML}-new.html xindex.html; \
        echo
record-image-size-diffs:
	$(MAKE) fix-image-sizes 2>&1 |tee image-size-diffs.txt
	sed 's,.*\(src="[^"]*"\).*\(width=.*\)"[^"]*,\1 \2,g' \
          image-size-diffs.txt >image-size-diffs2.txt

.PHONY: html help clean regenerate serve devserver publish ec2upload gateupload
.PHONY: fix-image-sizes record-image-size-diffs


# other targets ###############################################################

# this does regeneration from GATEwiki sources, Pandoc and the like
#@JINJAFILES=`find $(INPUTDIR) -name '*.jinja'`; \
#for f in $$JINJAFILES; do \
#         BASE=`echo $$f |sed 's,\.jinja$$,,'`; \
#         MKDF=$${BASE}.mkd; HTML=$${BASE}.html; \
#         [ ! -e $$MKDF -o $$f -nt $$MKDF ] && \
#    MD="`$(GETMETAS) $$f`" && \
#           $(RUNJINJA) $$f $$MKDF || :; \
#done
prepare: local-prepare
	@YAMS=`find $(INPUTDIR) -name '*.yam'`; \
        for f in $$YAMS; do \
          BASE=`echo $$f |sed 's,\.yam$$,,'`; HTML=$${BASE}.html; \
          [ ! -e $$HTML -o $$f -nt $$HTML ] && \
            $(Y2H) $$f && $(EPI) $$HTML || :; \
        done
	@PDCS=`find $(INPUTDIR) -name '*.mkd'`; \
	for f in $$PDCS; do \
          BASE=`echo $$f |sed 's,\.mkd$$,,'`; HTML=$${BASE}.html; \
          [ ! -e $$HTML -o $$f -nt $$HTML ] && \
	    MD="`$(GETMETAS) $$f`" && \
            $(PDC) $$f -o $$HTML && \
	    $(EPI) -M "$$MD" $$HTML || \
	    :; \
	done
# the old way:
#           echo $(PDC) $$f -M "extra-meta=$$MD" -o $$HTML && \

# finalise the output directory
finalise: local-finalise
	# to workaround pelican bug with anchors in relative pathnames we do
	# a final fixup over the generated htmls in the output directory
	@for f in `find $(OUTPUTDIR) -name '*.html'`; do \
          sed -e 's,">XXX\(.*\)XXX,\1">,g' $${f} >$${f}-$$$$; \
          mv $${f}-$$$$ $${f}; \
	done
	@for f in `find $(OUTPUTDIR) -name '*.xml'`; do \
          sed -e 's,"&gt;XXX\(.*\)XXX,\1"\&gt;,g' $${f} >$${f}-$$$$; \
          mv $${f}-$$$$ $${f}; \
	done
	@for f in `find $(OUTPUTDIR)/pages -name '*.html'`; do \
	  sed -n '/<div class="cow-contents">/,/^<\/ul><\/p><\/div>$$/p' \
            $${f} >$${f}-contents; \
          sed "/__CONTENTS__/ r $${f}-contents" $${f} >$${f}-$$$$; \
          mv $${f}-$$$$ $${f}; \
          rm -f $${f}-contents; \
        done
	# copy bare drafts as they are
	@for f in $(DRAFT_PAGES); do \
          cp -r $(INPUTDIR)/pages/$${f} $(OUTPUTDIR)/pages; \
        done
	# print tree
	$(MAKE) local-print

# various housekeeping files
google-site-verify:
	echo 'google-site-verification: google2bff225e702ae7d8.html' \
          >output/google2bff225e702ae7d8.html
robots:
	cp robots.txt output/robots.txt
favicon:
	cp $(INPUTDIR)/images/favicon.ico output

# compress html using http://code.google.com/p/htmlcompressor/
minify:
	java -jar $(SCRIPTS)/htmlcompressor-1.5.3.jar --preserve-line-breaks \
          -r output/ -o compressed-output/
	cd compressed-output && for f in `find . -name '*.html'`; do \
          mv $$f ../output/$${f}; done
	rm -rf compressed-output

# do a "publish" run to absolutise the URLs in the RSS feeds
fix-rss-feeds:
	mv output output.sav
	mkdir output
	$(MAKE) publish
	mv output/feeds feeds.sav
	rm -rf output
	mv output.sav output
	rm -rf output/feeds
	mv feeds.sav output/feeds
	for f in `find $(OUTPUTDIR)/feeds -name '*.xml'`; do \
          sed -e 's,"&gt;XXX\(.*\)XXX,\1"\&gt;,g' $${f} >$${f}-$$$$; \
          mv $${f}-$$$$ $${f}; \
	done

# make an archival copy of the .html files from the output directory
archive:
	rsync -aH --include='*.html' --include='*.css' --include='*.js' \
          --include='*.htc' --include='*.xml' --exclude='*.*' \
          output/ archives/archive-`date "+%Y-%m-%d"`
	cd archives && rm -f latest && ln -s archive-`date "+%Y-%m-%d"` latest
	@echo archived these files:
	@find archives/archive-`date "+%Y-%m-%d"` -type f

# diff the most recent archive htmls with the current output
archive-diff:
	@echo differences between latest archive html and output html:
	@echo 
	@cd archives/latest >/dev/null; \
          for f in `find . -type f`; do \
            cmp -s $$f ../../output/$$f || \
              ( echo $${f}: && \
                diff -y -W 175 --suppress-common-lines $$f ../../output/$$f \
                && echo ) || :; \
          done |more
	@echo 

# delete all the .htmls dependent on .yams
yam-clean:
	@YAMS=`find $(INPUTDIR) -name '*.yam'`; \
        for f in $$YAMS; do \
          BASE=`echo $$f |sed 's,\.yam$$,,'`; HTML=$${BASE}.html; \
          rm -f $$HTML; \
        done

# post; assume SLUG has the title/slug...
post:
	@[ -z "$${SLUG}" ] && { echo 'set SLUG to something!'; exit 1; } || :; \
	[ -z "$${POSTFILE}" ] && POSTFILE=`date "+%Y-%m-%d"`-$${SLUG}.yam; \
        OUT=$(INPUTDIR)/$${POSTFILE}; \
        [ -f $${OUT} ] || echo "A post about $${SLUG}..." > $${OUT}; \
        echo >>$${OUT}; \
        echo "created $${OUT}"; \
        git add -v $${OUT}; \
        cd $(INPUTDIR)/images/articles >/dev/null && \
        cp -n default.jpg $${SLUG}.jpg && cd thumbs >/dev/null && \
        cp -n default.jpg $${SLUG}.jpg && cd .. && \
        git add -v $${SLUG}.jpg thumbs/$${SLUG}.jpg; \
	echo '%meta(summary=TODO,tags=TODO)' >>$${OUT}; \
        echo "TODO: supply better versions of $${SLUG}.jpg and " \
          "thumbs/$${SLUG}.jpg in $(INPUTDIR)/images/articles" >>$${OUT}; \
	echo '*%(pages/TODO.html, Read the main article).*' >>$${OUT}; \
        echo; cat $${OUT}; echo
draft:
	@POSTFILE=$${SLUG}.yam; export POSTFILE; \
        $(MAKE) --no-print-directory post || exit 1; \
        OUT=$(INPUTDIR)/$${POSTFILE}; \
        echo >>$${OUT}; \
	echo '%meta(status=draft,summary=TODO,tags=TODO)' >>$${OUT}; \
	PUBNAME=`date "+%Y-%m-%d"`-$${SLUG}.yam; \
	echo 'TODO: remove draft status & rename to '$$PUBNAME >>$${OUT}; \
	echo created draft in $${OUT}
pdc-post:
	@[ -z "$${SLUG}" ] && { echo 'set SLUG to something!'; exit 1; } || :; \
	[ -z "$${POSTFILE}" ] && POSTFILE=$${SLUG}.mkd; \
        OUT=$(INPUTDIR)/$${POSTFILE}; \
        [ -f $${OUT} ] || echo "---" > $${OUT}; \
	echo "title: A post about $${SLUG}..." >> $${OUT}; \
        echo "created $${OUT}"; \
        git add -v $${OUT}; \
        cd $(INPUTDIR)/images/articles >/dev/null && \
        ln -s default.jpg $${SLUG}.jpg && cd thumbs >/dev/null && \
        ln -s default.jpg $${SLUG}.jpg && cd .. && \
	git add -v $${SLUG}.jpg thumbs/$${SLUG}.jpg; \
	echo 'summary: TODO' >>$${OUT}; \
	echo 'tags: TODO' >>$${OUT}; \
	echo 'date: '`date` >>$${OUT}; \
	echo '---' >>$${OUT}; \
	echo >>$${OUT}; \
        echo "TODO: supply better versions of $${SLUG}.jpg and " \
          "thumbs/$${SLUG}.jpg in $(INPUTDIR)/images/articles" >>$${OUT}; \
        echo; cat $${OUT}; echo

# checklinks
checklinks:
	rsync --delete -a output/ link-check-output; \
	cd link-check-output; \
        for f in `find . -name '*.html'`; do \
          sed -i \
            -e 's,https:,http:,g' \
            -e 's,http://$(SITE)/,/,g' \
            $$f; \
        done; \
        echo "starting http server in `pwd`; now run make linkchecker"; \
	$(PY) -m pelican.server; \
        :
linkchecker:
	linkchecker --no-warnings \
          --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:28.0) Gecko/20100101  Firefox/28.0" \
          http://localhost:8000; \
        :

# list all the .html files in the s3 bucket
s3list:
	s3cmd -r ls s3://$(SITE)                   >/tmp/$(SITE)-all.txt
#	s3cmd -r ls s3://$(SITE) | grep '\.html$$' >/tmp/$(SITE)-htmls.txt

# call picpage.sh to create content/picpage.html
picpage:
	cd content && $(PICPAGE) images && $(EPI) picpage.html || :
	mv content/picpage.html content/pages

.PHONY: prepare specials finalise minify archive archive-diff yam-clean post
.PHONY: draft fix-rss-feeds checklinks linkchecker s3list local-prepare
.PHONY: local-print
