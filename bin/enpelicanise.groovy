#!/usr/bin/env groovy
// enpelicanise.groovy

import java.util.regex.Matcher
import java.util.regex.Pattern
import java.text.DateFormat
import java.text.SimpleDateFormat
import groovy.text.SimpleTemplateEngine


println "oops -- not done yet (and might not need it...)"
System.exit(1)


// meta tags template
def metaTemplate = '''
<meta name=\"tags\" contents=\"pimoroni,learn\" />\n\
<meta name=\"date\" contents=\"${postDate}\" />\n\
<meta name=\"category\" contents=\"pimo\" />\n\
<meta name=\"author\" contents=\"Hamish Cunningham\" />\n\
<meta name=\"summary\" contents=\"${title}\" />\n\
'''

// bindings for the header
List templates = [ metaTemplate ]
String pubDate = new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss", Locale.UK).format(new Date()) + " +0000"
Map bindings = [ pubDate: pubDate ]

// head and tail
def headInstance = new SimpleTemplateEngine().createTemplate(headTemplate).make(bindings)
def tailInstance = new SimpleTemplateEngine().createTemplate(tailTemplate).make(bindings)
// println headInstance

// out dir
String dir = "out"
File dirFile = new File(dir)

// seed the export file
File out = new File(dirFile, "export-${'pdate -nl'.execute().text}.xml")
out << headInstance

// an id number for posts
int i = 100

// main loop: for each yam file
for(fname in args) {
  String fnameBase = fname.replace('.yam', '')
  File f = new File(fname)
  List dateStrings = f.text.findAll('_.*[12][0-9][0-9][0-9]_')
  int numDateStrings = dateStrings.size
  // println("${fname}: ${dateStrings}")
  // println "${fname}: ${numDateStrings}"

  // pages (no date means not a post)
  if(numDateStrings != 1) {
    command="cp ${fname} ${dir}"
    println command
    //// command.execute()
    continue
  }

  // the date from this file
  String dString = dateStrings[0]
  print("${fname}: ${dString} ==> ")

  // construct Date from dString
  Pattern p = ~/_.*\/? ?[a-zA-Z.]+ ([0-9.]{1,2})[stnr][thd] ([a-zA-Z.]+),? ([12][0-9][0-9][0-9])_/
  Matcher m = p.matcher(dString)
  List mlist = m[0]
  // println(mlist)
  String day = mlist[1]
  String month = ""
  switch(mlist[2]) {
    case "January":     month = "01";   break;
    case "Jan":         month = "01";   break;
    case "February":    month = "02";   break;
    case "Feb":         month = "02";   break;
    case "March":       month = "03";   break;
    case "Mar":         month = "03";   break;
    case "April":       month = "04";   break;
    case "Apr":         month = "04";   break;
    case "May":         month = "05";   break;
    case "May":         month = "05";   break;
    case "June":        month = "06";   break;
    case "Jun":         month = "06";   break;
    case "July":        month = "07";   break;
    case "Jul":         month = "07";   break;
    case "August":      month = "08";   break;
    case "Aug":         month = "08";   break;
    case "September":   month = "09";   break;
    case "Sept":        month = "09";   break;
    case "Sep":         month = "09";   break;
    case "October":     month = "10";   break;
    case "Oct":         month = "10";   break;
    case "November":    month = "11";   break;
    case "Nov":         month = "11";   break;
    case "December":    month = "12";   break;
    case "Dec":         month = "12";   break;
    default:            month="..";     break;
  }
  String year = mlist[3]
  // println "${year}-${month}-${day}  ${fname}"
  // DateFormat df = new SimpleDateFormat("EEE MMM dd HH:mm:ss z yyyy")
  DateFormat df = new SimpleDateFormat("MM dd yyyy HH:mm")
  // Date d = df.parse("Thu Apr 28 09:03:00 BST 2011")
  if(day == "..") day = "01"
  if(month == "..") month = "01"
  Date d = df.parse("${month} ${day} ${year} 23:58")
  println d
  // println "fname=${fname}\nfnameBase=${fnameBase}\nd=${d}\nfileTags=${fileTags}"

  // title: <title>A New Test Post</title>
/* this would be more portable:
String title = new File(${fname}).readLines()[0].trim() */
  String title = "print-line.sh 1 ${fname}".execute().text.trim()

  // name: <wp:post_name>a-new-test-post</wp:post_name>
  // link: <link>http://something.net/2012/05/02/a-new-test-post/</link>
  String postName = fnameBase.replaceFirst("[0-9-]+", "")
  String linkPath = fnameBase.replaceFirst("-", "/").replaceFirst("-", "/").replaceFirst("-", "/")
  String link = "http://something.net/${linkPath}/"

  // post content: <content:encoded><![CDATA[...]]></content:encoded>
  String content = new File("out/content-${fnameBase}.html").text

  // post pub date: <pubDate>Wed, 02 May 2012 12:44:02 +0000</pubDate>
  // post date: <wp:post_date>2012-05-02 12:44:02</wp:post_date>
  // post gmt date: <wp:post_date_gmt>2012-05-02 12:44:02</wp:post_date_gmt>
  String postPubDate = d.format("EEE, dd MMM yyyy HH:mm:ss") + " +0000"
  String postDate = gmtDate = d.format("yyyy-MM-dd HH:mm:ss")

  // guid: <guid isPermaLink="false">http://something.net/?p=21</guid>
  // id: <wp:post_id>21</wp:post_id>
  String postId = i++

  // excerpt: <excerpt:encoded><![CDATA[]]></excerpt:encoded>
  // (not done, 55 word thing should be ok)
  // String excerpt = content.replaceFirst(/^$.*/, "")

  // post template bindings
  Map b = [
    title: title,
    postName: postName,
    postPubDate: postPubDate,
    postDate: postDate,
    postId: postId,
    gmtDate: gmtDate,
    link: link,
    content: content,
    // excerpt: excerpt,
  ]

  // instantiate the post
  def postInstance =
    new SimpleTemplateEngine().createTemplate(postTemplate).make(b)
  out << postInstance
}

// terminate the export file
out << tailInstance
