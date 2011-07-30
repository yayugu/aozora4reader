# encoding: utf-8

# Original source is "青空文庫→TeX（ver. 0.9.5 2004/5/5 psitau）"
# see: http://psitau.kitunebi.com/aozora.html
#
# Also another source is "青空キンドル [Beta]"
# see: http://a2k.aill.org/
#
# Also another source is "aozora4reader"
# see: https://github.com/takahashim/aozora4reader

class Aozora4Reader

  PreambleLineNumber=13
  KANJIPAT = "[々〇〻\u3400-\u9FFF\uF900-\uFAFF※ヶ〆]"
  MAX_SAGE = 15

  def self.a4r(file)
    self.new(file).main
  end

  def initialize(file)
    @inputfile = file

    @jisage = false
    @log_text = []
    @line_num=0
    @gaiji = {}
    @gaiji2 = {}

    @html = ''
  end

  # UTF-8で出力
  def normalize(l)
    ##l.gsub!(/&/, '\\\\&')
    l.to_s
  end
  
  # 全角→半角
  def to_single_byte(str)
    s = str.dup
    if s =~ /[０-９]/
      s.tr!("１２３４５６７８９０", "1234567890")
    elsif s =~ /[一二三四五六七八九〇]/
      s.tr!("一二三四五六七八九〇", "1234567890")
    end
    case s
    when /\d十\d/
      s.sub!(/(\d)十(\d)/, '\1\2')
    when /\d十/
      s.sub!(/(\d)十/, '\{1}0')
    when /十\d/
      s.sub!(/十(\d)/, '1\1')
    when /十/
      s.sub!(/十/, "10")
    end
    if s =~/[！？]/
      s.tr!("！？", "!?")
    end

    return s
  end

  # ルビの削除(表題等)
  def remove_ruby(str)
    str.gsub(/\\ruby{([^}]+)}{[^}]*}/i){$1}
  end

  # プリアンブルの出力
  def preamble
    title = remove_ruby(@title)
    author = remove_ruby(@author)
    str = "<html>\n"
    str
  end

  # 底本の表示用
  def postamble
    #str = "<teihon>\n"
    str = '<ignore>'
    str
  end

  # アクセントの処理用
  # http://www.aozora.gr.jp/accent_separation.html
  # http://cosmoshouse.com/tools/acc-conv-j.htm
  def translate_accent(l)
    l.gsub!(/([ij]):/){"\\\"{\\#{$1}}"}
    l.gsub!(/([AIOEUaioeu])(['`~^])/){"\\#$2{#$1}"}
    l.gsub!(/([AIOEUaioeu]):/){"\\\"{#$1}"}
    l.gsub!(/([AIOEUaioeu])_/){"\\={#$1}"}
    l.gsub!(/([!?])@/){"#$1'"}
    l.gsub!(/([Aa])&/){"\\r{#$1}"}
    l.gsub!(/AE&/){"\\AE{}"}
    l.gsub!(/ae&/){"\\ae{}"}
    l.gsub!(/OE&/){"\\OE{}"}
    l.gsub!(/oe&/){"\\oe{}"}
    l.gsub!(/s&/){"\\ss{}"}
    l.gsub!(/([cC]),/){"\\c{#$1}"}
    l.gsub!(/〔/,'')
    l.gsub!(/〕/,'')
    return l
  end


  # 外字の処理用
  def translate_gaiji(l)
    if l =~/※［＃([^］]*)、([^、］]*)］/
      if @gaiji2[$1]
        l.gsub!(/※［＃([^］]*)、([^、］]*)］/){@gaiji2[$1]}
      end
    end
    ## ※［＃「姉」の正字、「女＋※［＃第3水準1-85-57］のつくり」、256-下-16］
    if l =~/※［＃([^］]*※［＃[^］]*］[^］]*)、([^、］]*)］/
      if @gaiji2[$1]
        l.gsub!(/※［＃([^］]*※［＃[^］]*］[^］]*)、([^、］]*)］/){@gaiji2[$1]}
      end
    end
    ## ※［＃「さんずい＋闊」］
    if l =~ /※［＃「([^］]+?)」］/
      if @gaiji2[$1]
        l.gsub!(/※［＃「([^］]+?)」］/){@gaiji2[$1]}
      end
    end

    if l =~ /※［＃[^］]*?※［＃[^］]*?[12]\-\d{1,2}\-\d{1,2}[^］]*?］[^］]*?］/
      l.gsub!(/※［＃([^］]*?)※［＃([^］]*?([12]\-\d{1,2}\-\d{1,2})[^］]*?)］([^］]*?)］/){"※\\footnote{#$1"+@gaiji[$3]+"#$4}"}
    end
    if l =~ /※［＃[^］]*?([12]\-\d{1,2}\-\d{1,2})[^］]*?］/
      if @gaiji[$1]
        l.gsub!(/※［＃([^］]*?([12]\-\d{1,2}\-\d{1,2})[^］]*?)］/){@gaiji[$2]}
      end
    end
    if l =~ /※［＃濁点付き片仮名([ワヰヱヲ])、.*?］/
      l.gsub!(/※［＃濁点付き片仮名([ワヰヱヲ])、.*?］/){ "\\ajLig{#{$1}゛}"}
    end
    if l =~ /※［＃感嘆符三つ.*］/
      l.gsub!(/※［＃感嘆符三つ.*?］/){ "<rensuji>!!!</rensuji>"}
    end

    if l =~ /※［＃.*?([A-Za-z0-9_]+\.png).*?］/
      l.gsub!(/※［＃([^］]+?)］/, "\\includegraphics{#{$1}}")
    end

    if l =~ /※［＃[^］]+?］/
      l.gsub!(/※［＃([^］]+?)］/, '※\\footnote{\1}')
    end

    if l =~ /※/
      STDERR.puts("Remaining Unprocessed Gaiji Character in Line #@line_num.")
      @log_text << normalize("未処理の外字が#{@line_num}行目にあります．\n")
    end
    return l
  end

  # ルビの処理用
  def translate_ruby(l)

    # 被ルビ文字列内に外字の注記があるばあい，ルビ文字列の後ろに移動する
    # ただし，順番が入れ替わってしまう
    while l =~ /※\\footnote\{[^(?:\\footnote)]+\}(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))*?《.+?》/
      l.sub!(/(※)(\\footnote\{[^(?:\\footnote)]+\})((?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))*?《.+?》)/, '\1\3\2')
    end

    # 被ルビ文字列内に誤記などの注記が存在する場合は、ルビの後ろに移動する
    while l =~ /(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?［＃[^］]*?］(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))*?《.+?》/
      l.sub!(/((?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?)(［＃[^］]*?］)((?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))*?《.+?》)/, '\1\3\2')
    end

    # ルビ文字列内に誤記などの注記が存在する場合は、ルビの後ろに移動する
    if l =~ /《[^》]*?［＃[^］]*?］[^》]*?》/
      l.gsub!(/(《[^》]*?)(［＃[^］]*?］)([^》]*?》)/, '\1\3\2')
    end

    # 一連のルビの処理
    # １ 縦棒ありの場合
    if l =~ /｜/
      l.gsub!(/｜(.+?)《(.+?)》/, '<ruby><rb>\1</rb><rt>\2</rt></ruby>')
    end

    # ２ 漢字および外字
    if l =~ /(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?《.+?》/
      l.gsub!(/((?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?)《(.+?)》/, '<ruby><rb>\1</rb><rt>\2</rt></ruby>')
    end

    # ３ ひらがな
    if l =~ /[あ-ん](?:[ぁ-んーヽヾ]|\\CID\{12107\})*?《.+?》/
      l.gsub!(/([あ-ん](?:[ぁ-んーヽヾ]|\\CID\{12107\})*?)《(.+?)》/, '<ruby><rb>\1</rb><rt>\2</rt></ruby>')
    end

    # ４ カタカナ
    if l =~ /[ア-ヴ](?:[ァ-ヴーゝゞ]|\\CID\{12107\})*?《.+?》/
      l.gsub!(/([ア-ヴ](?:[ァ-ヴーゝゞ]|\\CID\{12107\})*?)《(.+?)》/, '<ruby><rb>\1</rb><rt>\2</rt></ruby>')
    end

    # ５ 全角アルファベットなど
    if l =~ /[Ａ-Ｚａ-ｚΑ-Ωα-ωА-Яа-я・]+?《.+?》/
      l.gsub!(/([Ａ-Ｚａ-ｚΑ-Ωα-ωА-Яа-я・]+?)《(.+?)》/, '<ruby><rb>\1</rb><rt>\2</rt></ruby>')
    end

    # ６ 半角英数字
    if l =~ /[A-Za-z0-9#_\-\;\&.\'\^\`\\\{\} ]+?《.+?》/
      l.gsub!(/([A-Za-z0-9#_\-\;\&.\'\^\`\\\{\} ]+?)《(.+?)》/, '<ruby><rb>\1</rb><rt>\2</rt></ruby>')
    end
    if l =~ /《.*?》/
      STDERR.puts("Unknown ruby pattern found in #@line_num.")
      @log_text << normalize("未処理のルビが#{@line_num}行目にあります．\n")
    end

    return l
  end

  # 傍点の処理用
  def translate_bouten(l)
    bouten_list = [
                   ["傍点", "bou"],
                   ["白ゴマ傍点","sirogomabou"],
                   ["丸傍点","marubou"],
                   ["白丸傍点","siromarubou"],
                   ["黒三角傍点","kurosankakubou"],
                   ["白三角傍点","sirosankakubou"],
                   ["二重丸傍点","nijyuumarubou"],
                   ["蛇の目傍点","jyanomebou"]]

    bouten_list.each{ |name, fun|
      if l =~ /［＃「.+?」に#{name}］/
        l.gsub!(/(.+?)［＃.*?「\1」に#{name}］/){
          str = $1
          str.gsub!(/(\\UTF{.+?})/){ "{"+$1+"}"}
          str.gsub!(/(\\ruby{.+?}{.+?})/i){ "{"+$1+"}"}
          "<bou type=#{fun}>"+str+"</bou>"
        }
      end
    }

    if l =~ /［＃傍点］.+?［＃傍点終わり］/
      l.gsub!(/［＃傍点］(.+?)［＃傍点終わり］/){
        str = $1
        str.gsub!(/(\\UTF{.+?})/){ "{"+$1+"}"}
        str.gsub!(/(\\ruby{.+?}{.+?})/i){ "{"+$1+"}"}
        "<bou>"+str+"</bou>"
      }
    end
    return l
  end

  # 傍線の処理用
  def translate_bousen(l)
    if l =~ /［＃「.+?」に傍線］/
      l.gsub!(/(.+?)［＃「\1」に傍線］/, '\\bousen{\1}')
    end
    if l =~ /［＃「.+?」に二重傍線］/
      l.gsub!(/(.+?)［＃「\1」に二重傍線］/, '\\bousen{\1}')
    end
    if l =~ /［＃「.+?」に鎖線］/
      l.gsub!(/(.+?)［＃「\1」に鎖線］/, '\\bousen{\1}')
    end
    if l =~ /［＃「.+?」に破線］/
      l.gsub!(/(.+?)［＃「\1」に破線］/, '\\bousen{\1}')
    end
    if l =~ /［＃「.+?」に波線］/
      l.gsub!(/(.+?)［＃「\1」に波線］/, '\\bousen{\1}')
    end
    return l
  end

  # ルビの調整
  def tuning_ruby(l)

    # １ 直前が漢字の場合
    if l =~ /(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))\\ruby/
      l.gsub!(/((?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\})))\\ruby/, '\1\\Ruby')
    end

    # ２ 直後が漢字の場合
    if l =~ /\\ruby\{(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}\{(?:[^\\\{\}]|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))/
      l.gsub!(/\\ruby(\{(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}\{(?:[^\\\{\}]|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\})))/, '\\Ruby\1')
    end

    # ３ ルビが連続する場合
    while l =~ /\\(?:ruby|RUBY|Ruby)\{(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}\{(?:[^\\{}]|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}\\ruby/
      l.sub!(/\\(?:ruby|RUBY|Ruby)(\{(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}\{(?:[^\\{}]|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\})\\ruby/, '\\RUBY\1\\RUBY')
    end
  end

  # 外字用ハッシュを作成
  def load_gaiji
    datadir = File.dirname(__FILE__)+"/../data"
    File.open(datadir+"/gaiji.txt", "r:UTF-8") do |f|
      while gaiji_line = f.gets
        gaiji_line.chomp!
        key, data = gaiji_line.split
        @gaiji[key] = data
      end
    end

    File.open(datadir+"/gaiji2.txt", "r:UTF-8") do |f|
      while gaiji_line = f.gets
        gaiji_line.chomp!
        key, data = gaiji_line.split
        data.gsub(/#.*$/,'')
        @gaiji2[key] = data
      end
    end
  end


  # 本文の処理
  def body inputfile
    @line_num += PreambleLineNumber
    while line = inputfile.gets
      @line_num += 1
      line.chomp!

      break if line =~ /^底本/

      while line =~ /(.+?)［＃(「\1」は横?[１|一]文字[^］]*?)］/
        line = line.sub(/(.+?)［＃(「\1」は横?[１|一]文字[^］]*?)］/){"\\ajLig{"+to_single_byte($1)+"}"}
      end
      if line =~ /［＃改丁.*?］/
        line.sub!(/［＃改丁.*?］/, "\\cleardoublepage")
      end
      if line =~ /［＃改[頁|ページ].*?］/
        line.sub!(/［＃改[頁|ページ].*?］/, "<pagebreak />")
      end

      if line =~ /〔.*?〕/
        translate_accent(line)
      end

      if line =~ /※/
        translate_gaiji(line)
      end
      if line =~ /《.*?》/
        translate_ruby(line)
      end
      if line =~ /［＃(.+?)傍点］/
        translate_bouten(line)
      end
      if line =~ /［＃傍点］.+?［＃傍点終わり］/
        translate_bouten(line)
      end
      if line =~ /［＃「(.+?)」に(?:二重)?[傍鎖破波]線］/
        translate_bousen(line)
      end
      if line =~ /［＃この行.*?([１２３４５６７８９０一二三四五六七八九〇十]*)字下げ］/
        @html << "　" * to_single_byte($1).to_i
        line = line.sub(/［＃この行.*?字下げ］/, "")
        @line_num += 2
      end

      if line =~ /［＃ここから地から.+字上げ］/
        line.sub!(/［＃ここから地から([１２３４５６７８９０一二三四五六七八九〇十]*)字上げ］/){"\\begin{flushright}\\advance\\rightskip"+to_single_byte($1)+"zw"}
        @jisage = true
      end
      if line =~ /［＃ここで字上げ終わり］/
        line.sub!(/［＃ここで字上げ終わり］/){"\\end{flushright}"}
        @jisage = false
      end

      if line =~ /［＃ここから改行天付き、折り返して.*?字下げ］/
        if @jisage
          @html << "\\end{jisage}\n"
          @line_num += 1
        end
        line.sub!(/［＃ここから改行天付き、折り返して([１２３４５６７８９０一二三四五六七八九〇十]*)字下げ］/){"\\begin{jisage}{#{to_single_byte($1)}}\\setlength\\parindent{-"+to_single_byte($1)+"zw}"}
        @jisage = true
      end

      if line =~ /［＃.*?字下げ[^］]*?(?:終わり|まで)[^］]*?］/ 
        line = line.sub(/［＃.*?字下げ.*?(?:終わり|まで).*?］/, "")+"</jisage>"
        @jisage = false
      end
      if line =~ /［＃(ここから|これより|ここより|以下).+字下げ.*?］/
        if @jisage
          html << "</jisage>\n"
          @line_num += 1
        end
        line.sub!(/［＃(ここから|これより|ここより|以下).*?([１２３４５６７８９０一二三四五六七八九〇十]*)字下げ.*?］/){"<jisage num='"+to_single_byte($2)+"'>"}
        @jisage = true
      end
      if line =~ /^［＃ここから地付き］$/
        @jisage = true
        line = "\\begin{flushright}"
      end
      if line =~ /^［＃ここで地付き終わり］$/
        line = "\\end{flushright}"
        @jisage = false
      end

      if line =~ /［＃.*?地付き.*?］$/
        line = "\\begin{flushright}\n"+line.sub(/［＃.*?地付き.*?］$/, "\\end{flushright}")
        @line_num += 1
      elsif line =~ /［＃.*?地付き.*?］/
        line = line.sub(/［＃.*?地付き.*?］/, "\\begin{flushright}\n")+"\\end{flushright}"
        @line_num += 1
      end
      if line =~ /［＃.*?(?:行末|地)(?:から|より).*?([１２３４５６７８９０一二三四五六七八九〇十]*)字上.*?］$$/
        line = "\\begin{flushright}\\advance\\rightskip"+to_single_byte($1)+"zw\n"+line.sub(/［＃.*?(?:行末|地)(?:から|より).*?字上.*?］$/, "\\end{flushright}")
        @line_num += 1
      elsif line =~ /^(.*?)［＃.*?(?:行末|地)(?:から|より).*?([１２３４５６７８９０一二三四五六七八九〇十]*)字上.*?］(.*)$/
        line = $1+"\\begin{flushright}\\advance\\rightskip"+to_single_byte($2)+"zw\n"+$3+"\\end{flushright}"
        @line_num += 1
      end
      if line =~ /［＃「.+?」は返り点］/
        line.gsub!(/(.+)［＃「\1」は返り点］/, '\\kaeriten{\ajKunten{\1}}')
      end
      if line =~ /［＃[一二三上中下甲乙丙丁レ]*］/
        line.gsub!(/［＃([一二三上中下甲乙丙丁レ]*)］/, '\\kaeriten{\ajKunten{\1}}')
      end
      if line =~ /［＃（.*?）］/
        line.gsub!(/［＃（(.*?)）］/, '\\okurigana{\1}')
      end
      if line =~ /［＃「.+?」.*?ママ.*?注記］/
        line.gsub!(/(.+)［＃「\1」.*?ママ.*?注記］/, '\\ruby{\1}{ママ}')
      end

      if line =~ /［＃[^］]+（([^）]+.png).*?）[^］]+］/
        line.gsub!(/［＃[^］]+（([^）]+.png).*?）[^］]+］/, '\\sashie{\1}')
      end

      if line =~ /［＃([１２３４５６７８９０一二三四五六七八九〇十]*)字下げ］/
        num = to_single_byte($1).to_i
        if num > MAX_SAGE
          num = MAX_SAGE
        end
        @html << "　" * num
        line = line.sub(/［＃.*?字下げ］/, "")
      end

      ## ちょっと汚いけど二重指定の対策
      if line =~ /［＃「(.*?)」は縦中横］［＃「(.*?)」は中見出し］/
        line.gsub!(/(.*?)［＃「(\1)」は縦中横］［＃「(\1)」は中見出し］/){"<h4><rensuji>#{$1}</rensuji></h4>"}
      end

      if line =~ /［＃「(.*?)」は大見出し］/
        line.gsub!(/(.*?)［＃「(.*?)」は大見出し］/){"<h3>#{$1}</h3>"}
      end
      if line =~ /［＃「(.*?)」は中見出し］/
        line.gsub!(/(.*?)［＃「(.*?)」は中見出し］/){"<h4>#{$1}</h4>"}
      end
      if line =~ /［＃「(.*?)」は小見出し］/
        line.gsub!(/(.*?)［＃「(.*?)」は小見出し］/){"<h5>#{$1}</h5>"}
      end
      if line =~ /［＃小見出し］(.*?)［＃小見出し終わり］/
        line.gsub!(/［＃小見出し］(.*?)［＃小見出し終わり］/){"<h5>#{$1}</h5>"}
      end
      if line =~ /［＃中見出し］(.*?)［＃中見出し終わり］/
        line.gsub!(/［＃中見出し］(.*?)［＃中見出し終わり］/){"<h4>#{$1}</h4>"}
      end

      if line =~ /［＃ここから中見出し］/
        line.gsub!(/［＃ここから中見出し］/){"<h4>"}
      end
      if line =~ /［＃ここで中見出し終わり］/
        line.gsub!(/［＃ここで中見出し終わり］/){"</h4>"}
      end

      if line =~ /［＃ページの左右中央］/
        ## XXX とりあえず無視
        line.gsub!(/［＃ページの左右中央］/, "")
      end

      ## XXX 字詰めは1行の文字数が少ないので無視
      if line =~ /［＃ここから([１２３４５６７８９０一二三四五六七八九〇十]*)字詰め］/
        line.gsub!(/［＃ここから([１２３４５６７８９０一二三四五六七八九〇十]*)字詰め］/, "")
      end
      if line =~ /［＃ここで字詰め終わり］/
        line.gsub!(/［＃ここで字詰め終わり］/, "")
      end

      # XXX 割り注も無視
      if line =~ /［＃ここから割り注］/
        line.gsub!(/［＃ここから割り注］/, "")
      end
      if line =~ /［＃ここで割り注終わり］/
        line.gsub!(/［＃ここで割り注終わり］/, "")
      end

      if line =~ /［＃「(.*?)」は太字］/
        line.gsub!(/(.+)［＃「\1」は太字］/,'<b>\1</b>')
      end
      if line =~ /［＃「.+?」は縦中横］/
        line.gsub!(/(.+)［＃「\1」は縦中横］/, '<rensuji>\1</rensuji>')
      end
      if line =~ /［＃「(１)(／)(\d+)」は分数］/
        bunshi = to_single_byte($1)
        bunbo = $3
        line.gsub!(/(.+)［＃「.+?」は分数］/, "<rensuji>#{bunshi}/#{bunbo}</rensuji>")
      end
      if line =~ /［＃「.+?」は罫囲み］/
        line.gsub!(/(.+)［＃「\1」は罫囲み］/, '\\fbox{\1}')
      end
      if line =~ /［＃「(.+?)」は(本文より)?([１２３４５６])段階大きな文字］/
        line.gsub!(/([^［]+?)［＃「\1」は(本文より)?([１２３４５６])段階大きな文字］/) {
          num = to_single_byte($3).to_i
          "<font size='+#{num}'>#{$1}</font>"
        }
      end

      if line =~ /［＃「.+?」は斜体］/
        line.gsub!(/(.+)［＃「\1」は斜体］/){
          shatai = to_single_byte($1).tr("ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ","abcdefghijklmnopqrstuvwxyz")
          "<rensuji>\\textsl{"+shatai+"}</rensuji>"
        }
      end
      if line =~ /［＃「[０-９0-9]」は下付き小文字］/
        line.gsub!(/([A-Za-zａ-ｚＡ-Ｚαβδγ])([０-９0-9])［＃「\2」は下付き小文字］/){
          "$"+$1+"_{"+to_single_byte($2)+"}$"
        }
      end
      if line =~ /([^　]*)［＃ゴシック体］$/
        line.gsub!(/([^　]*)［＃ゴシック体］/){"{\\gtfamily #{$1}}"}
      end
      if line =~ /［＃「.+?」はゴシック体］/
        line.gsub!(/(.+?)［＃「\1」はゴシック体］/){"{\\gtfamily #{$1}}"}
      end

      if line =~ /［＃ここから横組み］(.*?)［＃ここで横組み終わり］/
        line.gsub!(/［＃ここから横組み］(.*?)［＃ここで横組み終わり］/){
          yoko_str = $1
          yoko_str.gsub!(/π/,"\\pi ")
          yoko_str.gsub!(/＝/,"=")
          yoko_str.gsub!(/(\d+)［＃「\1」は指数］/){"^{#{$1}}"}
          "$"+yoko_str+"$"
        }
      end
      line.tr!("┌┐┘└│─┏┓┛┗┃━→","┐┘└┌─│┓┛┗┏━┃↓")
      if line =~ /［＃改段］/
        line.sub!(/［＃改段］/, "<pagebreak />")
      end
      if line =~ /[aioeu]\^/i
        line.gsub!(/([aioeu])\^/i){ "\\\^{#{$1}}"}
      end
      if line =~ /[aioeu]\'/i
        line.gsub!(/([aioeu])\'/i){ "\\\'{#{$1}}"}
      end
      if line =~ /［＃天から.*?([１２３４５６７８９０一二三四五六七八九〇十]*)字下げ］/
        num = to_single_byte($1).to_i
        if num > MAX_SAGE
          num = MAX_SAGE
        end
        @html << "\\begin{jisage}{#{num}}\n"
        line = line.sub(/［＃天から.*?字下げ］/, "")+"\n\\end{jisage}"
      end

      line.gsub!(/［＃図形　□（四角）に内接する◆］/, '{\setlength{\fboxsep}{0pt}\fbox{◆}}')

      if line =~ /［＃[^］]+?］/
        line.gsub!(/［＃([^］]+?)］/, '<note>{\1}</note>')
      end
      if line =~ /\\ajD?Kunoji\{\}\}/
        line.gsub!(/(\\ajD?Kunoji)\{\}\}/, '\1}')
      end
      if line =~ /\\ruby/
        tuning_ruby(line)
      end
      if line =~ /^$/
        line = ""
      end
      line = normalize(line)+"\n\n"
      line.gsub!(/\\UTF\{(.*?)\}/, '<utf>\1</utf>')
      @html << line
    end
  end


  # 
  # メインパート
  # 
  def main
    load_gaiji()

    # プリアンブルの処理
    empty_line = 0
    in_note = false
    meta_data = []
    while empty_line < 2
      line = @inputfile.gets.chomp
      if in_note
        if line =~ /^-+$/
          in_note = false
          break
        end
      else
        if line =~ /^-+$/
          in_note = true
        else
          if line =~ /^$/
            empty_line += 1
          else
            if line =~ /《.*?》/
              translate_ruby(line)
            end
            meta_data << line
          end
        end
      end
    end

    @line_num +=  meta_data.size
    @title = normalize(meta_data.shift)
    case meta_data.size
    when 1
      @author = normalize(meta_data.shift)
    when 2
      @subtitle = normalize(meta_data.shift)
      @author = normalize(meta_data.shift)
    when 3
      @subtitle = normalize(meta_data.shift)
      @author = normalize(meta_data.shift)
      @subauthor = normalize(meta_data.shift)
    else
      @subtitle = normalize(meta_data.shift)
      @meta_data = []
      until meta_data.empty?
        @meta_data << normalize(meta_data.shift)
      end
      @subauthor = @meta_data.pop
      @author = @meta_data.pop
    end

    @html << preamble()

    @html << "<set bungaku_style='true' />"
    @html << "<title>" + @title + "</title>\n"
    @html << "<subtitle>" + @subtitle + "</subtitle>\n" if @subtitle
    @html << "<author>" + @author + "</author>\n"
    @html << "<subauthor>" + @subauthor + "</subauthor>\n" if @subauthor

    if @meta_data
      @meta_data.each do |data|
        @html << "<metadata>"+data+"</metadata>\n"
      end
    end

    # 本文の処理
    body @inputfile

    # 底本の処理
    @html << postamble()
    @html << normalize(line)+"\n"
    while line = @inputfile.gets
      line.chomp!
      @html << normalize(line)+"\n"
    end
    #@html << "\n</teihon></html>"
    @html << '</ignore></html>'
    if @log_text.size > 0
      until @log_text.empty?
        @html << @log_text.shift
      end
    end

    return @html
  end
end
