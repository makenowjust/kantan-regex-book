# はじめに

**正規表現**は様々なプログラミング言語で利用されている、テキスト処理のためのパターン言語です。
正規表現はテキストエディタでの検索や置換、入力文字列のバリデーションなどプログラミングの様々な分野で実用されています。
ある程度の規模のプログラムにおいて、正規表現を全く利用しない (利用していない) ということはほとんど無く、正規表現は今日のプログラミングにおいて非常に重要なパーツだと言えます。

JavaScriptやRubyといったプログラミング言語では正規表現はファーストクラスのリテラルとして実装されているため、とても簡単に利用できます。
例えば次のRubyプログラミングでは変数`foo`に入った文字列の部分に`fizz`か`buzz`が含まれるかどうかを、正規表現`/fizz|buzz/`を使ってチェックしています。

```ruby
foo =~ /fizz|buzz/
```

さらに、計算機科学 (コンピューターサイエンス) の分野においても、正規表現は重要な概念の一つです。
形式言語理論やオートマトン理論といった抽象的な理論の分野に限らず、コンパイラやデータマイニングなどの具体的な応用にも、正規表現は活用されています。

こういった重要性のある正規表現ですが、実際に利用しているプログラマの中でも「挙動が複雑でよく分からない」「予想外の動きをするのでバグの原因になる」といった意見があります。
他にも、正規表現のパターンと文字列によってはマッチング時間が爆発し、正常な時間で処理が行えなくなるReDoSと呼ばれる脆弱性の原因となることもあります。
これらの問題が生じる理由は、正規表現のバックトラックなどを用いたパターンに対する網羅的なマッチングが、通常のプログラミングで扱う逐次的な処理とはやや異なり、直感に反する動作をすることがあるためだと考えられます。

そこでこの本では、`kantan-regex`という小さな正規表現エンジンのRubyによる実装を通じて、正規表現マッチングの動作を説明します。
実際に作ってみることで、言葉で説明されるよりもよく理解できるのではないかと思います。

正規表現はある種、小さなプログラミング言語と言えます。
実際、この本では正規表現のマッチングを「正規表現をパース (構文解析)」「マッチング用のVMの命令列へと変換」「VMの実行」という流れで行います。
これは多くのプログラミング言語が動作すると似た流れになっていて、プログラミング言語の実装をしてみたい人が入門として実装するのにも適しています。

また、実装してみると分かりますが、正規表現エンジンは最適化などを除いたコアの部分だけであれば数百行程度で実装でき、かなり単純です。
そのため、一度実装すると、機能追加や最適化など様々なところに手を加えることができます。

それでは、正規表現エンジンの実装をはじめましょう。

## 本書のターゲット

この本は次のような方をターゲットとしています。

- 正規表現を普段から使っていて、より深く知りたい方。
- プログラミング言語を作ってみたいけれど、小さなものから始めたい方。

正規表現やプログラミング言語の基本についてはそこまで詳細に説明しないので、適宜調べてください。
とくに、Rubyの比較的新しい機能である`Data`型や`case ... in`によるパターンマッチなどを利用するので、注意してください。
