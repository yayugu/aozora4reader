$(function(){
  $("#url").submit(function(e){
    var link = "http://localhost:2525/azr?url=" + $("#url_text").attr('value');
    $("#url_generated").append("<a href=" + link + ">" + link + "</a>");
  });
});
