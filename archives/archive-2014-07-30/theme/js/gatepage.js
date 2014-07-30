Event.observe(document, 'dom:loaded', function(dle) {
  Event.observe(document.body, 'focusin', function(e) {
    $$('.menu li').each(function(it) {
      if(e.target.descendantOf(it)) {
        it.addClassName('hover');
      } else {
        it.removeClassName('hover');
      }
    });
    var anchor = e.findElement('a');
    if(anchor !== document) {
      Element.addClassName(anchor, 'hover');
    }
  });

  Event.observe(document.body, 'focusout', function(e) {
    var anchor = e.findElement('a');
    if(anchor !== document) {
      Element.removeClassName(anchor, 'hover');
    }
  });

});

