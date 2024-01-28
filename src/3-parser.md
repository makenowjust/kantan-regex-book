# 正規表現のパーサー

正規表現のパターンは[前の章](./2-spec.md)で説明した構文を持った文字列です。
そのため、マッチングを行うためにはまず、構文解析 (パース) をして、どのようなパターンなのかコンピュータが理解できるようにしなければなりません。
この構文解析を行う部分を**パーサー**と呼びます。
この章ではパターンのパーサーの実装をします。

> **NOTE**
> 
> この章は「正規表現の動作を理解する」という目標からは少し離れた内容になっています。
> そのため、場合によっては次の「抽象構文木 (AST)」の部分に目を通したのち、パーサーの実装をコピーして、[次の章](./4-backtrack-vm.md)に進んでも構いません。

## 抽象構文木 (AST)

パターンを構文解析した結果を表すデータ構造を、**抽象構文木** (AST) と呼びます。
そして、文字列からこの抽象構文木へと変換することが構文解析 (パース) になります。

抽象構文木は[`Data`](https://docs.ruby-lang.org/ja/latest/class/Data.html)を使って表すことにします。

```ruby
{{#include ../kantan-regex/ast.rb:base}}
```

それぞれどのような型か説明します。

- `Literal`は文字リテラルやエスケープ文字を表す型です。
  `value`にはその文字を表す長さ1の文字列が入ります。
  例えば1文字のパターン`a`は`Literal['a']`として表します。
- `Repetition`は繰り返しを表す型です。
  `child`は繰り返し対象の抽象構文木です。
  `quantifier`がどの繰り返しの種類かを表すパラメータで`:star`か`:plus`か`:question`のいずれかになります。
  例えばパターン`a*`は`Repetition[Literal['a'], :star]`として表します。
- `Choice`は選択を表す型で、`children`は抽象構文木の配列です。
  例えばパターン`a|b`は`Choice[[Literal['a'], Literal['b']]]`として表します。
- `Concat`は連接を表す型で、`children`は抽象構文木の配列です。
  例えばパターン`ab`は`Concat[[Literal['a'], Literal['b']]]`として表します。

グループ化はパターンのマッチ結果に影響しない構文のため、型としては定義していません。
例えば`a*`と`(a)*`はマッチする文字列は同じで、どちらも`Repetition[Literal['a'], :star]`で表します。

## パーサーの実装

パーサーの実装方法は、パーサージェネレーターを使う方法や、手書きでパーサーを実装する方法など、いくつか存在します。
今回はその中でも手書きで実装する**再帰下降パーサー**という方法を使うことにします。
再帰下降パーサーは文字列を複数の再帰関数 (メソッド) を用いて走査することで構文解析を行う方法です。

実装は`KantanRegex::Parser`クラスで行います。
このクラスは構文解析の度に生成されて、再帰下降パーサーの状態を管理します。

```ruby
{{#include ../kantan-regex/parser.rb:base_util}}
```

- インスタンス変数`@pattern`は構文解析対象の文字列で、`@offset`は現在の構文解析中の文字列上の位置です。
- `current_char`は現在の構文解析中の文字を返すメソッドで、`end?`は末尾に到達しているかを判定するメソッドです。
- `next_char`は構文解析中の文字を次に進めるメソッドです。

これらのメソッドを使って構文解析を行います。
基本的には各構文の優先順位に従ってメソッドを呼び出していきます。

```ruby
{{#include ../kantan-regex/parser.rb:base_impl}}
```

`KantanRegex::Parser`クラスの作成と`parse`メソッドの呼び出しを一度に行う`KantanRegex.parse`メソッドを追加しておきます。

```ruby
{{#include ../kantan-regex/parser.rb:base_entry}}
```

最後に`irb`からこれを使ってみます。

```irb
irb(main):001> load './kantan-regex/parser.rb'
=> true
irb(main):002> KantanRegex::Parser.parse('a*')
=>
#<data KantanRegex::Repetition
 child=#<data KantanRegex::Literal value="a">,
 quantifier=:star>
irb(main):003> KantanRegex::Parser.parse('(a|b)*c')
=>
#<data KantanRegex::Concat
 children=
  [#<data KantanRegex::Repetition
    child=
     #<data KantanRegex::Choice
      children=
       [#<data KantanRegex::Literal value="a">,
        #<data KantanRegex::Literal value="b">]>,
    quantifier=:star>,
   #<data KantanRegex::Literal value="c">]>
```

正しく動作してそうです。
