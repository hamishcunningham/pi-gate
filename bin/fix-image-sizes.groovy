#!/usr/bin/env groovy
// fix-images-sizes.groovy
// ian roberts, september 2013

@Grab(group='org.jsoup', module='jsoup', version='1.7.2')
import org.jsoup.*
import org.jsoup.nodes.*

import javax.imageio.*
import javax.imageio.stream.*

def imageSize = { String urlStr ->
  println "Determining dimensions of ${urlStr}"
  def details = [height:-1, width:-1, aspect:1.0]
  URL u = new URL(urlStr)
  ImageInputStream iis = ImageIO.createImageInputStream(u.openStream())
  try {
    Iterator<ImageReader> readers = ImageIO.getImageReaders(iis)
    if(readers.hasNext()) {
      ImageReader ir = readers.next()
      try {
        ir.setInput(iis)
        int imgIndex = ir.getMinIndex()
        details.height = ir.getHeight(imgIndex)
        details.width = ir.getWidth(imgIndex)
        details.aspect = ir.getAspectRatio(imgIndex)
      } finally {
        ir.dispose()
      }
    }
  } finally {
    iis.close()
  }

  println details
  return details
}.memoize() // memoize so we don't have to parse the same image more than once

for(htmlFile in args) {
  Document htmlDoc =
    Jsoup.parse(new File(htmlFile), null, new File(htmlFile).toURI().toString())
  htmlDoc.getElementsByTag("img").each { Element image ->
    String heightStr = image.attr("height")
    int height = heightStr.isInteger() ? heightStr.toInteger() : 0
    String widthStr = image.attr("width")
    int width = widthStr.isInteger() ? widthStr.toInteger() : 0
    if(!height || !width) {
      String imgUrl =
        image.attr("abs:src").replaceFirst("file:/", "file:./output/")
      if(!imgUrl) return

      def imgDetails = imageSize(imgUrl)
      if(!height && !width) {
        // case 1: neither height nor width
        if(imgDetails.height >= 0) {
          image.attr("height", "${imgDetails.height}")
        }
        if(imgDetails.width >= 0) {
          image.attr("width", "${imgDetails.width}")
        }
      } else if(!height) {
        // case 2: width specified but not height
        def newHeight = (width / imgDetails.aspect).round()
        image.attr("height", "${newHeight}")
      } else {
        // case 3: height specified but not width
        def newWidth = (height * imgDetails.aspect).round()
        image.attr("width", "${newWidth}")
      }
    }
  }
  htmlDoc.outputSettings().prettyPrint(false)
  new File(htmlFile + "-new.html").write(
      htmlDoc.outerHtml(), htmlDoc.outputSettings().charset().name())
}
