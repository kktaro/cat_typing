# CLAUDE.md

このファイルは Claude Code がこのリポジトリで作業する際のガイドです。

## プロジェクト概要

猫モチーフの日本語タイピングゲーム（Flutter Web）。猫テーマの長文を 1 本表示し、ユーザーが最初から最後まで日本語 IME で入力すると、クリアタイムと正確率が表示されるシンプル構成。落下・敵・レベルなどの複雑な要素は持たない MVP。

## 開発環境

- **Flutter**: 3.44.1（`mise.toml` で固定）
- **Dart**: 3.12.1
- **ターゲット**: Web のみ（iOS / Android / desktop は対象外）

```bash
mise install     # Flutter 3.44.1 を有効化
flutter pub get
flutter analyze
flutter run -d chrome
flutter build web --release  # 本番ビルド
```

## 技術スタック

- **状態管理**: Riverpod (`flutter_riverpod`)
- **入力方式**: 日本語 IME（`TextEditingController` で `composing` を監視し、変換確定時のみロジックに反映）
- **アセット方針**: 画像なし。絵文字（🐱😺😻😹😿）と Material Icons で代用

### 意図的に導入しないもの

- `freezed` / `riverpod_annotation` / `build_runner` — 規模に対して過剰。`@immutable` クラス + 手書き `copyWith` で十分
- `go_router` — 画面は Home / Game / Result の 3 枚のみ。`Navigator.push` / `pushReplacement` / `pop` で完結
- `intl` / `flutter_localizations` — 日本語ハードコードで OK

## 想定ディレクトリ構成

```
lib/
  main.dart                         # ProviderScope + runApp
  app.dart                          # MaterialApp、テーマ
  data/
    typing_texts.dart               # 猫テーマ長文（const リスト 3〜5 本）
  domain/
    typing_status.dart              # enum TypingStatus
    typing_session.dart             # イミュータブルなゲーム状態モデル
  ui/
    core/theme/app_theme.dart
    features/
      home/home_screen.dart
      game/
        game_screen.dart
        game_controller.dart        # NotifierProvider
        widgets/
          target_text_view.dart     # 既入力/未入力を色分けする RichText
          cat_face.dart             # 進捗連動の絵文字
          progress_header.dart      # 経過時間 + LinearProgressIndicator
      result/result_screen.dart
```

## ドメインモデル設計

`lib/domain/typing_session.dart` をイミュータブルクラスとして実装する。

- フィールド: `targetText` / `typedText` / `status` / `startedAt` / `finishedAt` / `mistakeCount`
- 派生プロパティ:
  - `correctPrefixLength`: `typedText` と `targetText` の先頭一致長
  - `isCompleted`: `typedText == targetText`
  - `progress`: `correctPrefixLength / targetText.length`
  - `elapsed`: `(finishedAt ?? DateTime.now()) - startedAt`
  - `accuracy`: `targetText.runes.length / (targetText.runes.length + mistakeCount)`

`Stopwatch` や `Timer.periodic` は使わない。経過時間は `DateTime.now() - startedAt` で都度計算する。

```dart
enum TypingStatus { notStarted, playing, finished }
```

## 状態管理設計

`lib/ui/features/game/game_controller.dart` に集約する。

- `selectedTextProvider`: 表示する文章を返す `Provider<String>`。デフォルトは `kCatTypingTexts.first`
- `tickerProvider`: 100ms tick の `StreamProvider.autoDispose<int>`。UI 再描画用（経過時間表示の更新トリガ）に使う。ロジックには使わない
- `gameControllerProvider`: `NotifierProvider.autoDispose<GameController, TypingSession>`
  - `build()`: `selectedTextProvider` の値で初期状態を生成
  - `onConfirmedTextChanged(String confirmed, String previousConfirmed)`: IME 確定済み文字列を受けて、初打鍵での `startedAt` 記録、誤入力カウント、完了判定（`finished` 遷移と `finishedAt` 記録）を行う
  - `reset()`: 初期状態に戻す

## 日本語 IME 入力の扱い

Flutter Web の `TextField.onChanged` は IME 変換中にも発火する（候補確定前のひらがなも流れてくる）。これだと「ねこ」と入力中に進捗が誤判定される。

対策: `TextEditingController` を直接購読し、`TextEditingValue.composing` が確定状態（`!isValid || isCollapsed`）のときだけロジックに通知する。

```dart
void _onTextChanged() {
  final v = _controller.value;
  if (!v.composing.isValid || v.composing.isCollapsed) {
    if (v.text != _lastConfirmed) {
      ref.read(gameControllerProvider.notifier)
         .onConfirmedTextChanged(v.text, _lastConfirmed);
      _lastConfirmed = v.text;
    }
  }
}
```

マッチング戦略: 「先頭一致長（`correctPrefixLength`）」で進捗判定。誤入力時は BackSpace で消して打ち直す運用。

`TextField` 設定:

- `autofocus: true`
- `maxLines: null`
- `enableSuggestions: false`
- `autocorrect: false`

## 画面構成

`Navigator.push` / `pushReplacement` / `pop` で遷移する。`go_router` は不要。

### HomeScreen
- 大きな 🐱 + タイトル「Cat Typing」
- スタートボタン → `Navigator.push(MaterialPageRoute(builder: (_) => GameScreen()))`

### GameScreen
- 上部: `progress_header.dart`（経過秒数 + LinearProgressIndicator、`tickerProvider` を watch）
- 中央: `target_text_view.dart`（既入力部分は緑/グレー、未入力は通常色の `RichText`）
- 右上: `cat_face.dart`（進捗連動の絵文字）
- 下部: 入力用 `TextField`
- `ref.listen(gameControllerProvider, (prev, next) { if (next.status == TypingStatus.finished) Navigator.pushReplacement(...); })` で完了を検知し Result に遷移

### ResultScreen
- クリアタイム（秒、小数 1 桁）
- 正確率（%）
- 「もう一度」ボタン → `gameControllerProvider.notifier.reset()` → Home に戻す

## 猫モチーフ表現

画像アセットは作らず、絵文字と Material Icons で代用する。フォントサイズで存在感を出す（72〜120sp）。

進捗連動の表情変化（`cat_face.dart`）:

- 0〜30%: 🐱（通常）
- 30〜70%: 😺（笑顔）
- 70〜99%: 😻（やる気）
- 100%: 😹（完了）
- 誤入力直後（`mistakeCount` が直前より増えた瞬間）: 😿 を 500ms 表示してから戻す（`AnimatedSwitcher` + 短時間タイマー）

## 手動検証チェックリスト

`flutter run -d chrome` で起動後に以下を確認:

- [ ] ホームのスタートボタンで Game に遷移する
- [ ] TextField がオートフォーカスされ、即座に日本語入力できる
- [ ] IME 変換中の候補が進捗バーに反映**されない**（確定時のみ反映）
- [ ] 「ねこ」→「猫」と漢字変換で確定したときだけ進捗が進む
- [ ] BackSpace で誤入力を消すと進捗も巻き戻る
- [ ] 全文入力完了で Result に自動遷移
- [ ] Result の「もう一度」で Home に戻り、再スタート可
- [ ] 経過時間がプレイ中は更新され、Result では停止している
- [ ] 進捗に応じて猫の表情（🐱😺😻😹）が切り替わる
- [ ] 誤入力直後に 😿 が一瞬出る

## 次セッションでの実装着手手順

1. `pubspec.yaml` に `flutter_riverpod: ^2.6.1` を追加し `flutter pub get`
2. `lib/domain/typing_status.dart` と `lib/domain/typing_session.dart` を実装（テスト可能な純粋ロジック層から着手）
3. `lib/data/typing_texts.dart` に猫テーマ長文を 3〜5 本（各 80〜150 文字程度の自然な日本語）配置
4. `lib/ui/features/game/game_controller.dart` で `GameController` と Provider 群を実装
5. `lib/ui/features/game/game_screen.dart` で IME 監視ロジックと画面構築
6. `target_text_view.dart` / `cat_face.dart` / `progress_header.dart` を実装
7. `home_screen.dart` / `result_screen.dart` を実装
8. `lib/app.dart` / `lib/main.dart` を組み立てて `ProviderScope` で包む
9. `flutter run -d chrome` で実機確認、上記チェックリストを通す
