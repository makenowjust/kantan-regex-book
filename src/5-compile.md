# 正規表現からのコンパイル

ここでは、正規表現からVMの命令列への変換 (**コンパイル**) を実装します。
そして、公開するAPIを整理して、正規表現エンジンとしての実装を完成させます。

## 正規表現のコンパイル

正規表現からVMの命令列への変換は、正規表現の抽象構文木を再帰的に辿っていくことで行います。

それぞれの抽象構文木の型について、次のようにしてコンパイルしていきます。

### `Literal[value]`

`char`命令に対応しているので、`[:char, value]`にコンパイルします。

### `Concat[children]`

`children`を順番にコンパイルしていきます。

### `Choice[children]`

`children = [child1, child2]`のように2要素の場合で考えます。
このとき、次のようにコンパイルします。

```
+--------o [:push, (*1)]
|          ... child1のコンパイル結果 ...
| +------o [:jump, (*2)]
+-|-> (*1) ... child2のコンパイル結果 ...
  +-> (*2) ... 続くコンパイル結果 ...
```

`children`が3要素以上ある場合も同様に、最後の要素以外には`push`命令と`jump`命令を配置するようにします。

### `Repetition[child, :star]`

次のようにコンパイルします。

```
+-o +-> (*2) [:push, (*1)]
|   |        ... childのコンパイル結果 ...
|   +------o [:jump, (*2)]
+-----> (*1) ... 続くコンパイル結果 ...
```

### `Repetition[child, :plus]`

次のようにコンパイルします。
`:star`と比べて`push`命令の位置が変わっているだけです。

```
+---> (*2) ... childのコンパイル結果 ...
| +------o [:push, (*1)]
+-|------o [:jump, (*2)]
  +-> (*1) ... 続くコンパイル結果 ...
```

### `Repetition[child, :question]`

次のようにコンパイルします。
`:star`のコンパイル結果から`jump`命令が無くなったもので、単純になっています。

```
+------o [:push, (*1)]
|        ... childのコンパイル結果 ...
+-> (*1) ... 続くコンパイル結果 ...
```

## コンパイルの実装

それでは、これらのコンパイルを実装します。

実装は`KantanRegex::Compiler`クラスで行います。
このクラスはコンパイルの度に生成されて、コンパイル中の`program`を管理します。

```ruby
{{#include ../kantan-regex/compiler.rb:base}}
```

`insn`という命令を追加するメソッドや、コンパイルの起点となる`compile_root`メソッドを持っています。

実際に抽象構文木を辿るのは`compile`メソッドで、このメソッドの`case ... in`で先ほど説明したコンパイルの方法を実装しています。
`Choice`の場合がやや複雑ですが、注意深く処理を追えば何をやっているのか理解できると思います。

## 公開APIの実装

最後に、公開APIである`KantanRegex`クラスと`KantanRegex#match`メソッドを実装します。
これは、ここまで実装してきたものを使えば簡単に実装できます。

```ruby
{{#include ../kantan-regex/kantan-regex.rb:base}}
```

これを`irb`から読み込んで使ってみましょう。

```irb
irb(main):001> load './kantan-regex/kantan-regex.rb'
=> true
irb(main):002> KantanRegex.new('(a|ab)c').match('abc')
=> 0...3
irb(main):003> KantanRegex.new('a*ab').match('aaab')
=> 0...4
irb(main):004> KantanRegex.new('a*ab').match('bc')
=> nil
```

[前の章](./4-backtrack-vm.md)で説明した選択や繰り返しが正しく実装されていないといけない例も、上手く動作しているように見えます。

これにて`kantan-regex`の実装はひとまず完了となります。
おつかれさまでした。
