// Google Analytics
if (location.href.indexOf('norconex.com') != -1) {
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-23162620-1']);
  _gaq.push(['_setDomainName', 'norconex.com']);
  _gaq.push(['_trackPageview']);
  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
}

// Re-order and modify elements for enhanced display
var pageURL = window.location.href;
var isInFrame =  self != top;
var pom = {};

$( document ).ready(function() {
    pom.docRoot = $('#pom').data('doc-root');
    pom.projectName = $('#pom').data('project-name');
    pom.projectVersion = $('#pom').data('project-version');
    pom.projectURL = $('#pom').data('project-url');
    pom.projectShortName = pom.projectName.replace('Norconex ', '');
    
    doTopNavBar();
    doHeader();
    doContentContainer();
    
    $('.toast').toast();
});

//==============================================================================
// TOP NAV BAR
//==============================================================================
function doTopNavBar() {
    var navBar = `
        <nav id="topNav" class="navbar nav-justified navbar-expand-lg navbar-dark bg-primary py-0">

          <a name="navbar.top"></a>
          <div class="skipNav"><a href="#skip.navbar.top" title="Skip navigation links">Skip navigation links</a></div>
          <a name="navbar.top.firstrow"></a>
          
          <a class="navbar-brand" href="${pom.projectURL}">
            <img id="imgLogo" src="${pom.docRoot}norconex-logo-white.svg" height="24" title="Norconex" alt="Norconex">
            <span style="font-size: 20px;">${pom.projectShortName}</span>
            <small><small>${pom.projectVersion}</small></small>
          </a>
          <button class="navbar-toggler" type="button" 
              data-toggle="collapse" data-target="#navbarSupportedContent" 
              aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
          </button>
      
          <div class="collapse navbar-collapse" id="navbarSupportedContent">
            <ul id="navbarActions" class="navbar-nav ml-auto">
              <li class="nav-item dropdown">
                <a class="btn btn-sm py-1 my-2 mx-2 btn-primary text-light nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                  View
                </a>
                <div id="navigateDropdown" class="dropdown-menu" aria-labelledby="navbarDropdown">
                </div>
              </li>

              <li class="nav-item dropdown">
                <a class="btn btn-sm py-1 my-2 mx-2 btn-primary text-light nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                  Jump To
                </a>
                <div id="jumpToDropdown" class="dropdown-menu" aria-labelledby="navbarDropdown">
                  <h6 class="dropdown-header">Summary</h6>
                  <div class="dropdown-divider"></div>
                  <h6 class="dropdown-header">Details</h6>
                </div>
              </li>

              <li id="navbarFrames" class="nav-item">
                <div class="btn-group btn-group-sm py-1 my-1 mx-2 text-nowrap" role="group" aria-label="Frames or no frames">
                </div>
              </li>

              <li id="navbarPrevNext" class="nav-item">
                <div class="btn-group btn-group-sm py-1 my-1 mx-2 text-nowrap" role="group" aria-label="Previous or next class">
                </div>
              </li>
            </ul>
          </div>
          <a name="skip.navbar.top"></a>
        </nav>`;
      $(navBar).prependTo($('body'));
      
      // Remove bottom nav:
      $('body > .bottomNav + .subNav').remove();
      $('body > .bottomNav').remove();
      
      // Main menu option (Navigate):
      $('body > .topNav > .navList > li').each(function() {
          var item = $(this).children().first();
          if (!$(item).is('a')) {
              var lbl = $(this).text().toLowerCase();
              var cls = 'disabled';
              if ($(this).hasClass("navBarCell1Rev")) {
                  cls = 'active';
              }
              item = $('<a href="#" class="' + cls + '">' + $(this).text() + '</a>');
          }
          $(item).addClass('dropdown-item');
          $(item).appendTo('#navigateDropdown');
      });
      $('body > .topNav').remove();

      // Insert All classes in between prev/next;
      if (!isInFrame) {
          var item = $('#allclasses_navbar_top > li').children().first();
          $(item).addClass('nav-link btn btn-primary text-light px-3');
          $(item).appendTo('#navbarPrevNext div');
      }
      
      // Frames/No Frames and Next/Previous:
      $('body > .subNav > .navList > li').each(function() {

          // Next/Previous:
          var lbl = $(this).text().toLowerCase();
          if (/prev|next/.test(lbl)) {
              var item = $(this).children().first();
              if ($(item).is('a')) {
                  $(item).addClass('nav-link btn btn-primary text-light px-3');
                  if (/prev/.test(lbl)) {
                      $(item).prepend('<i class="fas fa-chevron-left"></i>&nbsp;');
                      $(item).prependTo('#navbarPrevNext div');
                  } else {
                      $(item).append('&nbsp;<i class="fas fa-chevron-right"></i>');
                      $(item).appendTo('#navbarPrevNext div');
                  }
              }
          }
          
          // Frames/No Frames:
          else if (/frames$/.test(lbl)) {
              var item = $(this).children().first();
              if ($(item).is('a')) {
                  if (/\?/.test($(item).attr('href'))) {
                      $(item).prepend('<i class="fas fa-columns"></i>&nbsp;');
                      if (isInFrame) {
                          $(item).addClass('active');
                      }
                  } else {
                      $(item).prepend('<i class="far fa-window-maximize"></i>&nbsp;');
                      if (!isInFrame) {
                          $(item).addClass('active');
                      }
                  }
                  $(item).addClass('nav-link btn btn-primary text-light px-3');
              }
              $(item).appendTo('#navbarFrames div');
          }
      });
      
      // Summary:
      $('body > .subNav > div > .subNavList:first-child > li').each(function() {
          var item = $(this).children().first();
          if ($(item).is('a')) {
              $(item).addClass('dropdown-item');
              $(item).insertBefore('#jumpToDropdown .dropdown-divider');
          }
      });
      $('body > .subNav > div > .subNavList:first-child').remove();

      // Details:
      $('body > .subNav > div > .subNavList:first-child > li').each(function() {
          var item = $(this).children().first();
          if ($(item).is('a')) {
              $(item).addClass('dropdown-item');
              $(item).appendTo('#jumpToDropdown');
          }
      });
      $('body > .subNav').remove();
}

//==============================================================================
// HEADER
//==============================================================================
function doHeader() {
    $('body > .header').addClass('container-fluid');

    // package:
    var elSubTitle = $('body > .header > .subTitle');
    var packageName = $(elSubTitle).text();
    $(elSubTitle).empty();
    $(elSubTitle).append('<span class="text-secondary">Package: </span>');
    $(elSubTitle).append('<span id="packageName">' + packageName + '</span>');
    
    // class name:
    var elTitle = $('body > .header > h2')
    $(elTitle).addClass('text-secondary');
    $(elTitle).html($(elTitle).html().replace(
            /^(Class)\s+(.*?)(&lt;.*|$)/,
            '$1: <span id="className" class="text-body">$2</span>$3'));
    renameElement($(elTitle), 'h1');
    var className = $('#className').text();
    var defaultCopyType = localStorage.dropdownCopy;
    if (!defaultCopyType) {
        defaultCopyType = 'copy-full';
    }
    
    // Copy button:
    $(`<div class="btn-group btn-group-sm ml-3" title="Copy to clipboard">
      <button id="btnCopy" type="button" class="btn btn-outline-primary">
        <i class="fas fa-clipboard"></i>
      </button>
      <button type="button" class="btn btn-outline-primary dropdown-toggle 
          dropdown-toggle-split" id="dropdownMenuCopy" data-toggle="dropdown" 
          aria-haspopup="true" aria-expanded="false" data-reference="parent">
        <span class="sr-only">Toggle Dropdown</span>
      </button>
      <div id="dropdownCopy" class="dropdown-menu aria-labelledby="dropdownMenuCopy">
        <a id="copy-full"  class="dropdown-item" href="#"><i class="fas fa-signature mr-2"></i>Full name</a>
        <a id="copy-short" class="dropdown-item" href="#"><i class="fas fa-signature fa-xs mr-2"></i>&nbsp;Short name</a>
        <a id="copy-html"  class="dropdown-item" href="#"><i class="fas fa-code mr-2"></i>HTML link</a>
        <a id="copy-md"    class="dropdown-item" href="#"><i class="fab fa-markdown mr-2"></i>Markdown link</a>
      </div>
    </div>`).appendTo('body > .header > h1.title');
    $('#' + defaultCopyType).addClass('active');

    // Copy notif.
    $(`<div id="copyToast" class="toast border border-info" data-delay="2000"
        style="position: absolute; top: 50px; right: 10px; z-index: 2000;">
      <div class="toast-header text-info">
        <i class="fas fa-clipboard"></i>&nbsp;
        <strong class="mr-auto">Copied!</strong>
        <button type="button" class="ml-2 mb-1 close" data-dismiss="toast" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="toast-body text-info">
        Successfully copied.
      </div>
    </div>`).appendTo('body');

    // Clicked: do the copy
    $('#dropdownCopy a, #btnCopy').click(function() {
        var text;
        var toastBody;
        var copyType = $(this).attr('id');
        if (copyType === 'btnCopy') {
            copyType = defaultCopyType;
        }
        
        if (copyType === 'copy-short') {
            text = className;
            toastBody = 'Class short name copied.';
        } else if (copyType === 'copy-html') {
            text = '<a href="' + window.location.href
                 + '" title="Link to ' + className + ' class documentation">'
                 + className + '</a>';
             toastBody = 'Class copied as an HTML link.';
        } else if (copyType === 'copy-md') {
            text = '(' + className + ')[' + window.location.href + ']';
            toastBody = 'Class copied as a Markdown link.';
        } else { // copy-full
            text = packageName + '.' + className;
            toastBody = 'Class fully qualified name copied.';
        }
        copyToClipboard(text);
        $('#' + defaultCopyType).removeClass('active');
        $('#' + copyType).addClass('active');
        defaultCopyType = copyType;
        localStorage.dropdownCopy = copyType;
        $('#copyToast > .toast-body').text(toastBody);
        $('#copyToast').toast('show');
    });
}

//==============================================================================
// CONTENT CONTAINER
//==============================================================================
function doContentContainer() {
    $('body > .contentContainer').addClass('container-fluid');
    $('body > .contentContainer > .description > ul > li div.block').attr(
            'id', 'classDoc');

    // either this:
    $(`<div class="card bg-light border-dark">
         <!--<div class="card-header">Class Documentation</div>-->
         <div id="classDocContainer" class="card-body text-dark">
         </div>
       </div>`).prependTo('body > .contentContainer');
    $('#classDoc').prependTo('#classDocContainer');

    // or this:
//    $('#classDoc').prependTo('body > .contentContainer');

    
    //test:
    //$('h1').appendTo('.card-header');
}

//==============================================================================
// UTILITIES
//==============================================================================
function renameElement(element, newName) {
    if (element) {
        var newElement = $(element).get(0).outerHTML
                .replace(/^<\w+/, '<' + newName)
                .replace(/<\/\w+>$/, '</' + newName + '>');
        $(element).replaceWith(newElement);
    }
}
function copyToClipboard(text) {
    var $temp = $("<input>");
    $("body").append($temp);
    $temp.val(text).select();
    document.execCommand("copy");
    $temp.remove();
}

//TODO add a copy-to-clipboard button next to class for ease of copying
// in config file.

//TODO maybe offer a button that copies the link as HTML link or markdown link
// for easy cutnpaste

//TODO offer the above two todo as a dropdown of options next to class name