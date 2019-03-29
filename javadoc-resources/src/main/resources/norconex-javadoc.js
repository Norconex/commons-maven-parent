/*
 * Norconex JavaDoc JavaScript
 */

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

// Global vars
var pom = {};
var page = {};

$(document).ready(function() {
    
    initGlobalVars();
    
    doForAllPages();
    
    // Call page-specific function:
    eval('doPage' + page.navName + '();');
    
    $('.toast').toast();
});

//==============================================================================
// INIT: GLOBAL VARS
//==============================================================================
function initGlobalVars() {

    // Values set in Maven POM
    pom.docRoot = $('#pom').data('doc-root');
    pom.projectName = $('#pom').data('project-name');
    pom.projectVersion = $('#pom').data('project-version');
    pom.projectURL = $('#pom').data('project-url');
    pom.projectShortName = pom.projectName.replace('Norconex ', '');

    // Page details
    page.url = window.location.href.replace(/\#$/, '');
    page.inFrame = self != top;
    page.navName = $('body > .topNav > .navList > li.navBarCell1Rev').text();
}

//==============================================================================
// ALL PAGES
//==============================================================================
function doForAllPages() {
    _doForAllPages_TopNavBar();
    _doForAllPages_HeadFoot();
    
    if (page.navName != 'Use' && page.navName != 'Deprecated') {
        $('table > caption').remove();
    }
    
    $('body > .contentContainer').addClass('container-fluid');
    
    $('.deprecationComment').addClass('text-danger');
}

// ALL PAGES: Top Nav Bar
//--------------------------------------
function _doForAllPages_TopNavBar() {
    var navBar = [
        '<nav id="topNav" class="navbar navbar-expand-sm navbar-dark bg-primary py-0">',
          '<a name="navbar.top"></a>',
          '<div class="skipNav"><a href="#skip.navbar.top" title="Skip navigation links">Skip navigation links</a></div>',
          '<a name="navbar.top.firstrow"></a>',
          '<a class="navbar-brand" href="' + pom.projectURL + '">',
            '<img id="imgLogo" src="' + pom.docRoot + 'norconex-logo-white.png" height="24" title="Norconex" alt="Norconex">',
            '<span style="font-size: 20px;">' + pom.projectShortName + '</span>',
            '<small><small>' + pom.projectVersion + '</small></small>',
          '</a>',
          '<button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">',
            '<span class="navbar-toggler-icon"></span>',
          '</button>',
          '<div class="collapse navbar-collapse" id="navbarSupportedContent">',
            '<ul id="navbarActions" class="navbar-nav ml-auto">',
              '<li class="nav-item dropdown">',
                '<a class="btn btn-sm py-1 my-2 btn-primary text-light nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">',
                  'View',
                '</a>',
                '<div id="navigateDropdown" class="dropdown-menu" aria-labelledby="navbarDropdown">',
                '</div>',
              '</li>',
              '<li id="jumpToDropdownList" class="nav-item dropdown">',
                '<a class="btn btn-sm py-1 my-2 ml-3 btn-primary text-light nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">',
                  'Jump To',
                '</a>',
                '<div id="jumpToDropdown" class="dropdown-menu" aria-labelledby="navbarDropdown">',
                  '<h6 class="dropdown-header">Summary</h6>',
                  '<div class="dropdown-divider"></div>',
                  '<h6 class="dropdown-header">Details</h6>',
                '</div>',
              '</li>',
              '<li id="navbarFrames" class="nav-item">',
                '<div class="btn-group btn-group-sm py-1 my-1 ml-3 text-nowrap" role="group" aria-label="Frames or no frames"></div>',
              '</li>',
              '<li id="navbarPrevNext" class="nav-item">',
                '<div class="btn-group btn-group-sm py-1 my-1 ml-3 text-nowrap" role="group" aria-label="Previous or next class"></div>',
              '</li>',
            '</ul>',
          '</div>',
          '<a name="skip.navbar.top"></a>',
        '</nav>'
      ].join("\n");
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
                  $('body').attr('id', 'page' + $(this).text());
              }
              item = $('<a href="#" class="' + cls + '">' + $(this).text() + '</a>');
          }
          $(item).addClass('dropdown-item');
          $(item).appendTo('#navigateDropdown');
      });
      $('body > .topNav').remove();

      // Insert All classes in between prev/next;
      if (!page.inFrame) {
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
                      if (page.inFrame) {
                          $(item).addClass('active');
                      }
                  } else {
                      $(item).prepend('<i class="far fa-window-maximize"></i>&nbsp;');
                      if (!page.inFrame) {
                          $(item).addClass('active');
                      }
                  }
                  $(item).addClass('nav-link btn btn-primary text-light px-3');
              }
              $(item).appendTo('#navbarFrames div');
          }
      });
      
      
      // Jump to dropdown
      if (page.navName == 'Class') {
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

          $('#jumpToDropdown > a:contains("Constr")').text('Constructor');
      } else {
          $('#jumpToDropdownList').remove();
      }

      $('body > .subNav').remove();
}

// ALL PAGES: Header and Footer
//--------------------------------------
function _doForAllPages_HeadFoot() {
    $('body > .header').addClass('container-fluid');
    $('body > .header:first').addClass('bg-light pb-0 mb-2 border-bottom');
    
    $('body > p.legalCopy').addClass('container-fluid p-3 text-center');
    $('body > p.legalCopy small').addClass('d-inline-block');
}


//==============================================================================
// PAGE: Overview
//==============================================================================
function doPageOverview() {
    $('body > .header > .subTitle + p').remove();
    $('body > .header > .subTitle').addClass('my-3');
    
    var table = $('table.overviewSummary');
    
    $(table).wrap($('<div>').addClass('px-3'));
    
    bootstrapTable(table);
    $(table).addClass('table-sm');
}


//==============================================================================
// PAGE: Package
//==============================================================================
function doPagePackage() {
    $('body > .header > .docSummary + p').remove();
    $('body > .header > .docSummary').addClass('pb-2');
    $('body > .contentContainer').addClass('mt-3');
    
    bootstrapTable($('table.typeSummary'));
    unwrapFromList($('table.typeSummary'));
    $('table.typeSummary').addClass('table-sm');
    
    $('a[name="package.description"] + h2').remove();
    $('a[name="package.description"] + div').remove();

    $('table.typeSummary td.colLast').each(function () {
        if (getOwnText(this) == 'Deprecated') {
            $(this).addClass('text-muted font-weight-bold');
            $(this).find('.deprecationComment').removeClass('text-danger').addClass('font-weight-normal');
        }
    });
}


//==============================================================================
// PAGE: Class
//==============================================================================

function doPageClass() {
    _doPageClass_Header();
    _doPageClass_Description();
    _doPageClass_Summary();
    _doPageClass_Details();
}
function _doPageClass_Header() {
    // package:
    var elSubTitle = $('body > .header > .subTitle');
    var packageName = $(elSubTitle).text();
    $(elSubTitle).empty();
    $(elSubTitle).append('<a id="packageName" href="package-summary.html">' + packageName + '</a>');

    // class name:
    var elTitle = $('body > .header > h2')
    if ($(elTitle).html()) {
        $(elTitle).html($(elTitle).html().replace(/^Class\s+/, ''));
        var className = $(elTitle).text();
        renameElement($(elTitle), 'h1');
    }

    var defaultCopyType = getLocalStorage('dropdownCopy', 'copy-full');

    // Copy button:
    $([
        '<div class="btn-group btn-group-sm ml-3" title="Copy to clipboard">',
          '<button id="btnCopy" type="button" class="btn btn-outline-primary">',
            '<i class="fas fa-clipboard"></i>',
          '</button>',
          '<button type="button" class="btn btn-outline-primary dropdown-toggle dropdown-toggle-split" id="dropdownMenuCopy" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" data-reference="parent">',
            '<span class="sr-only">Toggle Dropdown</span>',
          '</button>',
          '<div id="dropdownCopy" class="dropdown-menu aria-labelledby="dropdownMenuCopy">',
            '<a id="copy-full"  class="dropdown-item" href="#"><i class="fas fa-signature mr-2"></i>Full name</a>',
            '<a id="copy-short" class="dropdown-item" href="#"><i class="fas fa-signature fa-xs mr-2"></i>&nbsp;Short name</a>',
            '<a id="copy-html"  class="dropdown-item" href="#"><i class="fas fa-code mr-2"></i>HTML link</a>',
            '<a id="copy-md"    class="dropdown-item" href="#"><i class="fab fa-markdown mr-2"></i>Markdown link</a>',
          '</div>',
        '</div>'
    ].join("\n")).appendTo('body > .header > h1.title');
    $('#' + defaultCopyType).addClass('active');

    // Copy notif.
    $([
        '<div id="copyToast" class="toast border border-dark" data-delay="2000" style="position: absolute; top: 50px; right: 10px; z-index: 2000;">',
          '<div class="toast-header text-dark">',
            '<i class="fas fa-clipboard"></i>&nbsp;',
            '<strong class="mr-auto">Copied!</strong>',
            '<button type="button" class="ml-2 mb-1 close" data-dismiss="toast" aria-label="Close">',
              '<span aria-hidden="true">&times;</span>',
            '</button>',
          '</div>',
          '<div class="toast-body text-secondary">',
            'Successfully copied.',
          '</div>',
        '</div>'
    ].join("\n")).appendTo('body');

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
            text = '<a href="' + page.url
                 + '" title="Link to ' + className + ' class documentation">'
                 + className + '</a>';
             toastBody = 'Class copied as an HTML link.';
        } else if (copyType === 'copy-md') {
            text = '(' + className + ')[' + page.url + ']';
            toastBody = 'Class copied as a Markdown link.';
        } else { // copy-full
            text = packageName + '.' + className;
            toastBody = 'Class fully qualified name copied.';
        }
        copyToClipboard(text);
        $('#' + defaultCopyType).removeClass('active');
        $('#' + copyType).addClass('active');
        defaultCopyType = copyType;
        setLocalStorage('dropdownCopy', copyType);
        $('#copyToast > .toast-body').text(toastBody);
        $('#copyToast').toast('show');
    });
}

function _doPageClass_Description() {
    var content = $('body > .contentContainer');
    
    $(content).find('> .description > ul > li div.block').attr('id', 'classDesc');

    //--- Class description: ---
    $('<div id="classPanel" class="text-justify pl-3"></div>').prependTo(content);
    $('#classDesc').appendTo('#classPanel');
    
    //--- Class details: ---
    $('<hr><div class="my-3"><dl id="classDetails" '
            + 'class="row py-2 my-0"></dl></div>').appendTo('#classPanel');

    // Class signature
    var classSign = $(content).find('> .description > ul > li > pre').html();
    if (classSign) {
        $('<dt/>').text('Class Signature:').appendTo('#classDetails');
        $('<dd/>').append(classSign).appendTo('#classDetails');
    }

    // Type hierarchy
    var typeHier = $(content).find('> .inheritance');
    if (typeHier) {
        $('<dt/>').text('Type Hierarchy:').appendTo('#classDetails');
        $('<dd/>').append(typeHier).appendTo('#classDetails');
    }
    
    // Other details
    var otherDetails = $(content).find('> .description > ul > li > dl > *');
    if (otherDetails) {
        $(otherDetails).appendTo('#classDetails');
    }
    $('#classDetails').find('code').contents().unwrap();
    $('#classDetails').find('> dt:contains("All Implemented Interfaces:")')
            .text('Impl. Interfaces:')
            .attr('title', 'All Implemented Interfaces:');
    $('#classDetails').addClass('text-left');
    $('#classDetails > dt').addClass('col-md-3 col-lg-2');
    $('#classDetails > dd').addClass('col-md-9 col-lg-10');

    $(content).find('> .description').remove();
}

function _doPageClass_Summary() {

    $('body > .contentContainer > .summary').attr('id', 'summaryPanel');
    var summary = $('#summaryPanel'); 
    $(summary).find('ul.blockList, ul.blockListLast, li.blockList').contents().unwrap();
    
    $(summary).find('> table.memberSummary').each(function() {
        $(this).wrap($('<div>').addClass('pl-3'));
        $(this).addClass('table border');
        var tbody = $(this).find('> tbody');
        $(tbody).find('> tr:first-child').wrap('<thead>');
        $(tbody).find('> thead').insertBefore(tbody);
        $(this).find('> thead').addClass('thead-light');
    });

    // Constructor Summary
    $('h3:contains("Constructor Summary")').attr('id', 'constrSummary');
    renameElement($('#constrSummary'), 'h2');

    // Method Summary
    $('h3:contains("Method Summary")').attr('id', 'methodSummary');
    renameElement($('#methodSummary'), 'h2');
    
    $(summary).find('> code').wrap('<div class="codePanel">');
    $(summary).find('> .codePanel').addClass("ml-3 mb-3 pl-2 py-2 border");

    $(summary).find('> h2').addClass('bg-dark text-light pl-2 pb-1');
    $(summary).find('> h3').addClass('bg-light border text-dark pl-2 py-2 ml-3 mb-0');
    
}

function _doPageClass_Details() {
    $('body > .contentContainer > .details').attr('id', 'detailsPanel');
    var details = $('#detailsPanel'); 
    
    $(details).find('> ul > li > ul > li > ul > li').each(function() {
        $(this).removeClass('blockList');
        $(this).addClass('detailPanel');
        renameElement($(this), 'div');
    });

    $(details).find('ul.blockList, ul.blockListLast, li.blockList').contents().unwrap();
    $(details).find('> h3').each(function() {
        renameElement($(this), 'h2');
    });
    
    $(details).find('> .detailPanel > h4').each(function() {
        $(this).insertBefore($(this).parent());
    })
    $(details).find('> h4').each(function() {
        renameElement($(this), 'h3');
    });
    $(details).find('> .detailPanel').addClass("ml-3 mb-3 pl-2 pt-2 pb-0 border");

    $(details).find('> h2').addClass('bg-dark text-light pl-2 pb-1');
    $(details).find('> h3').addClass('bg-light border text-dark pl-2 py-2 ml-3 mb-0');
    
    // method signature on one line
    $(details).find('> .detailPanel > pre').each(function() {
        $(this).html($(this).html().replace(/\s+/gm, ' '));
    });
}


//==============================================================================
// PAGE: Use
//==============================================================================
function doPageUse() {
    $('body > .classUseContainer').addClass('container-fluid');
    
    renameElement($('body > .header > h2'), 'h1');
    var title = $('body > .header > h1.title').html();
    title = title.replace(/(Uses of Class\s*<br>)/mg, '<div class="titleHeading pt-3 text-muted">$1</div>');
    $('body > .header > h1.title').html(title);

    var table = $('table.useSummary');
    bootstrapTable($(table));
    unwrapFromList($(table));
    $(table).wrap($('<div>').addClass('px-3'));
    $(table).addClass('table-sm');
}


//==============================================================================
// PAGE: Tree
//==============================================================================
function doPageTree() {
    $('body > .header > ul').prependTo($('body > .contentContainer'));
    $('body > .header > .packageHierarchyLabel').prependTo($('body > .contentContainer'));
}


//==============================================================================
// PAGE: Deprecated
//==============================================================================
function doPageDeprecated() {
    $('body > .header > ul').prependTo($('body > .contentContainer'));
    $('body > .header > h2').prependTo($('body > .contentContainer'));

    var table = $('table.deprecatedSummary');
    bootstrapTable($(table));

}


//==============================================================================
// PAGE: Help
//==============================================================================
function doPageHelp() {

}


//==============================================================================
// PAGE: Index
//==============================================================================
function doPageIndex() {
    $('body > .contentContainer > dl > dt').addClass('bg-light border pl-2');
    $('body > .contentContainer > dl > dd').addClass('border border-top-0 pl-2');
}


//==============================================================================
// UTILITIES
//==============================================================================

// Gets an element text, without the text of its children
function getOwnText(el) {
    return $(el).contents().get(0).nodeValue.trim();
}

// Remove direct parent(s) that are UL or LI.
function unwrapFromList(el) {
    $(el).each(function() {
        if ($(this).parent('ul,li').length > 0) {
            $(this).unwrap();
            unwrapFromList(this);
        }
    });
}

// If more than one tbody and no thead, assume first tbody is thead 
function bootstrapTable(table) {
    $(table).each(function() {
        if ($(this).find('> tbody').length > 1) {
            renameElement($(this).find('> tbody:first'), 'thead');
        }
        $(this).addClass('table border');
        $(this).find('> thead').addClass('thead-light');
    });
} 

function renameElement(element, newName) {
    if (element && $(element).get(0) && $(element).get(0).outerHTML) {
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


function getLocalStorage(key, defaultValue) {
    try {
        var value = localStorage.getItem(key);
        if (!value) {
            return defaultValue;
        }
    } catch (e) {
        return defaultValue;
    }
}
function setLocalStorage(key, value) {
    try {
        localStorage.setItem(key, value);
    } catch (e) {
        // swallow
    }
}
