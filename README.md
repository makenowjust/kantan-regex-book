# kantan-regex-book

『作って学ぶ正規表現エンジン』のリポジトリです。
このリポジトリには以下の内容が含まれます。

- `kantan-regex` (自作する正規表現エンジン) のソースコード (`kantan-regex/`ディレクトリ)
- 『作って学ぶ正規表現エンジン』の本文のMarkdownファイル (`src/`ディレクトリ)

## 開発方法

開発には[mdBook](https://rust-lang.github.io/mdBook/index.html)を使っています。
なので、`mdbook`をインストールしてください。

次のコマンドで`src/`ディレクトリ以下の内容がHTMLに変換されてブラウザに表示されます。

```console
$ mdbook serve --open
```

`mdbook serve`コマンドはMarkdownファイルを更新すると自動で再変換を行うので、執筆を進められるはずです。

## ライセンス

CC-0

(C) 2024 Hiroya Fujinami (a.k.a. TSUYUSATO "[MakeNowJust](https://github.com/makenowjust)" Kitsune)
