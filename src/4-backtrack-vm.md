# バックトラック型VM

今回は、正規表現マッチングを**バックトラック型VM**で実行します。
この章では、なぜバックトラック型VMが必要なのかを説明したのち、バックトラック型VMの仕様を解説し、実装します。

## なぜバックトラック型VMが必要なのか

バックトラック型VMの説明に入る前に「なぜバックトラック型VMが必要なのか」について説明します。

`kantan-regex`では正規表現マッチングを、正規表現をバックトラック型VMの命令列にコンパイルして実行することで実現します。
どうして、こんなに回りくどいことをしなければいけないのでしょうか？

理由は簡単に言うと「分岐や繰り返しの挙動を正しく実装するため」となります。

もう少し詳細に説明します。
例えば、抽象構文木をマッチ対象の文字列と同時に再帰的に辿っていく方針で正規表現マッチングを実装するとします。

すると、次のような抽象構文木`tree`、マッチ対象の文字列`input`、マッチ中の位置`pos`の引数を受け取って、マッチした場合は位置の数値を、マッチに失敗した場合は`nil`を返すメソッドで実装することになります。

```ruby
def naive_match(tree, input, pos)
  case tree
  in KantanRegex::Literal[value]
    if input[pos] == value
      pos + 1
    else
      nil
    end
  in KantanRegex::Concat[children]
    children.each do |child|
      pos = naive_match(child, input, pos)
      return nil unless pos
    end
    pos
  in KantanRegex::Repetition[child, quantifier] # TODO
  in KantanRegex::Choice[children] # TODO
  end
end
```

この方針でも`Literal`と`Concat`は上手く実装できます。
しかし、`Repetition`や`Choice`の実装はどうでしょうか？

選択は左側から優先的にマッチしていきます。
そのため、次のように順番に`match`を呼び出して、最初にマッチしたものを返すようにすれば実装できそうに思えます。

```ruby
def naive_match(tree, input, pos)
  case tree
  in KantanRegex::Literal[value] # 省略
  in KantanRegex::Concat[children] # 省略
  in KantanRegex::Repetition[child, quantifier] # TODO
  in KantanRegex::Choice[children]
    children.each do |child|
      choice_pos = naive_match(child, input, pos)
      return choice_pos if choice_pos
    end
    nil
  end
end
```

ですが、実はこれは上手く動作しません。

パターン`(a|ab)c`を考えます。
これは`ac`か`abc`にマッチするパターンのはずです。
しかし、これに対応するを抽象構文木を`tree`として、`naive_match(tree, "abc", 0)`を呼び出しても`3`が返らず`nil`が返る (つまりマッチしていない) ことになります。
どうしてこうなるのかと言うと、`naive_match`では`Choice`の1つマッチする部分を見つけたら他がマッチするかどうかを考慮せず、結果を考慮してしまいます。
そのため、2つ目以降のマッチする部分を選んだ場合に正しく全体がマッチする場合に、上手く動作しなくなってしまいます。

繰り返しの場合も素朴に実装すると、可能な限りマッチするのではなく、繰り返し回数を減らさなければいけないようなパターンのときに、上手く動作しなくなります。
例えばパターンが`a*ab`の場合に、`ab`にマッチしなくなってしまいます。

選択や繰り返しの動作を正しく実装するためには、複数のマッチの可能性を上手く扱えなければいけません。
`match`メソッドが複数のマッチ結果を返すように実装することでも良いのですが、そうするとパフォーマンス上の問題があります。

そこで、バックトラック型のVMを使うことで、この複数のマッチの可能性を自然に扱えるようになります。
こちらはパフォーマンス上の問題もありません。
そのため、実際の正規表現エンジンの実装でも、バックトラック型のVMが利用されることが多いです。

## バックトラック型VMの仕様

ここからはバックトラック型VMの仕様を実装しつつ説明していきます。

バックトラック型VMは、次のパラメータを受け取って動作します。

- `program`: バックトラック型VMの命令列 (配列)
- `input`: マッチ対象の入力文字列
- `start_pos`: マッチ開始位置

そして、次の内部の状態を持っています。

- `pc`: マッチ中の`program`のインデックス
- `pos`: マッチ中のインデックス
- `stack`: バックトラック先を記憶するスタック

これらの値を変化させるのが、`program`に格納された命令です。
`program`は次の命令 (1要素目がシンボルの配列) の配列になります。

- `[:push, backtrack_pc]`: `backtrack_pc`と`pos`の組を`stack`にプッシュして、`pc`をインクリメントする。
- `[:jump, next_pc]`: `pc`を`next_pc`に変更する。
- `[:char, c]`: `input[pos] == c`なら`pc`と`pos`をインクリメントして、そうでないなら`stack`をポップしてその値を`pc`と`pos`に変更する (バックトラックする)。`stack`が空の場合はマッチ失敗となる。
- `[:match]`: マッチを成功として`pos`を返す。

なんと、これら4種類の命令だけで正規表現の基本的な機能は実装できてしまいます。
どのように実現するのかは[次の章](./5-compile.md)で説明します。

## バックトラック型VMの実装

それでは、仕様に沿ってバックトラック型VMを実装していきましょう。

バックトラック型VMは`KantanRegex::BacktrackVM`クラスに実装します。
このクラスはマッチの度に作り直されることを想定していて、`program`と`input`を受け取ります。

```ruby
{{#include ../kantan-regex/backtrack_vm.rb:base}}
```

実際にVMの実行をするのは`exec`メソッドで、こちらでさらに`start_pos`を受け取ります。
`loop`の中にある`case ... in`が`program`の命令を処理している部分になります。

さらに、`KantanRegex::BacktrackVM.exec`メソッドが定義されていて、これは最初にマッチが


これを`irb`で読み込んで試しています。

```irb
irb(main):001> load './kantan-regex/backtrack_vm.rb'
=> true
irb(main):002* program =
irb(main):003*   [[:push, 3],
irb(main):004*    [:char, 'a'],
irb(main):005*    [:jump, 0],
irb(main):006>    [:match]]
=> [[:push, 3], [:char, "a"], [:jump, 0], [:match]]
irb(main):007> KantanRegex::BacktrackVM.exec(program, 'aaa')
=> 0..3
```

ここで用いた`program`はパターン`a*`に相当するものなので、正しい結果になっていることが分かります。
