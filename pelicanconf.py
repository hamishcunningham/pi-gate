#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = u'Hamish Cunningham'
SITENAME = u'Pi GATE — Sheffield Pi-Tronics'
#SITEURL = 'http://pi.gate.ac.uk'
SITEURL = ''
PUBURL = 'https://pi.gate.ac.uk'
TIMEZONE = 'Europe/London'
DEFAULT_LANG = u'en'

# Feeds
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
FEED_DOMAIN = 'https://pi.gate.ac.uk'
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
STATIC_PATHS = ['files', 'images', 'pages/images', '.htaccess', '.htpasswd']
FILENAME_METADATA = ('(?P<date>\d{4}-\d{2}-\d{2}).*')
PAGE_EXCLUDES = (['basics', 'airpi-files'])
ARTICLE_EXCLUDES = (['pages', 'basics', 'piroomba', 'airpi-files'])
MONTH_ARCHIVE_SAVE_AS = 'posts/{date:%Y}/{date:%m}/index.html'
YEAR_ARCHIVE_SAVE_AS = 'posts/{date:%Y}/index.html'
#THEME = 'theming/large-blue-fish'
#THEME = 'theming/small-yellow-fish'
THEME = 'theming/medium-red-fish'
ARTICLE_URL = 'posts/{date:%Y}/{date:%m}/{date:%d}/{slug}/'
ARTICLE_SAVE_AS = 'posts/{date:%Y}/{date:%m}/{date:%d}/{slug}/index.html'

TWITTER_USERNAME = 'PiTronics'
GOOGLE_ANALYTICS = 'UA-41812045-1'
DISQUS_SITENAME = 'pi-gate'

# didn't seem to work:   IGNORE_FILES = (['magpi'])
