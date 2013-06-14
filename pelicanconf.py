#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = u'Hamish Cunningham'
SITENAME = u'Pi GATE'
SITEURL = ''

TIMEZONE = 'Europe/London'

DEFAULT_LANG = u'en'

# Feed generation is usually not desired when developing
#FEED_ALL_ATOM = None
#CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None

FEED_ALL_ATOM = 'feeds/all.atom.xml'
CATEGORY_FEED_ATOM = 'feeds/%s.atom.xml'

# Blogroll
#LINKS =  (('Raspberry Pi', 'http://www.raspberrypi.org/'),
#          ('GATE', 'http://gate.ac.uk/'),)

# Social widget
#SOCIAL = (('You can add links in your config file', '#'),
#          ('Another social link', '#'),)

DEFAULT_PAGINATION = 10

# Uncomment following line if you want document-relative URLs when developing
#RELATIVE_URLS = True

MARKUP = ('rst', 'md', 'html')

#DEFAULT_DATE_FORMAT = ('%Y-%d-%m %H:%M')
FILES_TO_COPY = (('.htaccess', '.htaccess'), ('.htpasswd', '.htpasswd'),)
STATIC_PATHS = (['images', 'pages/images'])
FILENAME_METADATA = ('(?P<date>\d{4}-\d{2}-\d{2}).*')
PAGE_EXCLUDES = (['basics'])
ARTICLE_EXCLUDES = (['pages', 'basics', 'piroomba'])
MONTH_ARCHIVE_SAVE_AS = 'posts/{date:%Y}/{date:%m}/index.html'
YEAR_ARCHIVE_SAVE_AS = 'posts/{date:%Y}/index.html'
#THEME = 'large-blue-fish'
#THEME = 'small-yellow-fish'
THEME = 'medium-red-fish'
ARTICLE_URL = 'posts/{date:%Y}/{date:%m}/{date:%d}/{slug}/'
ARTICLE_SAVE_AS = 'posts/{date:%Y}/{date:%m}/{date:%d}/{slug}/index.html'

TWITTER_USERNAME = 'hcunningham'
