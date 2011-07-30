$(function(){
  $("#url").submit(function(e){
    var link = "http://localhost:2525/azr?url=" + $("#url_text").attr('value');
    $("#url_generated").append("<a href=" + link + ">" + link + "</a>");
  });
});

function addPaginationLinks(searcher) {
  var cursor = searcher.cursor;
  var curPage = cursor.currentPageIndex;
  var pagesDiv = $('<div />').addClass('gsc-cursor-box');
  for (var i = 0; i < cursor.pages.length; i++) {
    var page = cursor.pages[i];
    if (curPage == i) {
      pagesDiv.append(' ' + page.label + ' ');
    }
    else {
      var link = $('<a />');
      link.attr('href', 'javascript:siteSearch.gotoPage(' + i + ');');
      link.html(page.label);
      pagesDiv.append(' ');
      pagesDiv.append(link);
      pagesDiv.append(' ');
    }
  }
  pagesDiv.appendTo($('#searchResult'));
}

function searchComplete(searchControl, searcher) {
  if (searcher.results && searcher.results.length > 0) {
    var searchResults = $('#searchResult');
    searchResults.html('');

    var baseUrl = "http://localhost:2525/";

    addPaginationLinks(searcher);

    var results = searcher.results;
    for (var i = 0; i < results.length; i++) {
      var result = results[i];
      var resultContainer = $('<div />');
      resultContainer.addClass('gsc-result').appendTo(searchResults);

      var anchor = $('<a />').attr('href', result.url);
      var title = result.titleNoFormatting.replace(/図書カード：/, "");
      anchor.html(title);

      $('<div />').addClass('gsc-title').append(anchor).appendTo(resultContainer);

      $('<div />').html(result.content).appendTo(resultContainer);

      var download = $('<div />');
      download.appendTo(resultContainer);

      var account = $('#account').val();

      var url = baseUrl + "azr?url=" + encodeURIComponent(result.url);
      var downloadLink = $('<a />');
      downloadLink.attr('href', url);
      downloadLink.addClass('gsc-keeper');
      downloadLink.html(url);
      download.append(downloadLink);
      download.append('&nbsp;');

    }
    addPaginationLinks(searcher);
  }
}

google.load('search', '1', {language : 'ja'});
google.setOnLoadCallback(function() {
  var drawOptions   = new google.search.DrawOptions();
  var searchControl = new google.search.SearchControl();
  siteSearch = new google.search.WebSearch();

  drawOptions.setDrawMode(google.search.SearchControl.DRAW_MODE_TABBED);
  drawOptions.setSearchFormRoot(document.getElementById("searchForm"));

  searchControl.setLinkTarget(google.search.Search.LINK_TARGET_SELF);
  searchControl.setResultSetSize(google.search.Search.LARGE_RESULTSET);
  searchControl.setSearchCompleteCallback(this, searchComplete);

  siteSearch.setSiteRestriction("www.aozora.gr.jp");
  siteSearch.setQueryAddition("+図書カード");
  siteSearch.setRestriction(
    google.search.Search.RESTRICT_SAFESEARCH,
    google.search.Search.SAFESEARCH_OFF
    );

  searchControl.addSearcher(siteSearch);
  searchControl.draw(null, drawOptions);
});

