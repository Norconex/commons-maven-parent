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

$( document ).ready(function() {
    
    var pom = {};
    pom.docRoot = $('#pom').data('doc-root');
    pom.projectName = $('#pom').data('project-name');
    pom.projectVersion = $('#pom').data('project-version');
    pom.projectURL = $('#pom').data('project-url');
    pom.projectShortName = pom.projectName.replace('Norconex ', '');
    
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
              <div class="btn-group btn-group-sm py-1 my-1 mx-2" role="group" aria-label="Frames or no frames">
              </div>
            </li>

            <li id="navbarPrevNext" class="nav-item">
              <div class="btn-group btn-group-sm py-1 my-1 mx-2" role="group" aria-label="Previous or next class">
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
                    $(item).prepend('<span class="navIcon">&#9665;&nbsp;</span>');
                    $(item).prependTo('#navbarPrevNext div');
                } else {
                    $(item).append('<span class="navIcon">&nbsp;&#9655;</span>');
                    $(item).appendTo('#navbarPrevNext div');
                }
            }
        }
        // Frames/No Frames:
        else if (/frames$/.test(lbl)) {
            var item = $(this).children().first();
            if ($(item).is('a')) {
                if (/\?/.test($(item).attr('href'))) {
                    $(item).prepend('<span class="navIcon">&#9703;&nbsp;</span>');
                    if (isInFrame) {
                        $(item).addClass('active');
                    }
                } else {
                    $(item).prepend('<span class="navIcon">&#8414;&nbsp;&nbsp;</span>');
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
    
    
    
});


//TODO add a copy-to-clipboard button next to class for ease of copying
// in config file.

//TODO maybe offer a button that copies the link as HTML link or markdown link
// for easy cutnpaste

//TODO offer the above two todo as a dropdown of options next to class name