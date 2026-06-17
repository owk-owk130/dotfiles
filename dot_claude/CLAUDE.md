# CLAUDE.md

## Conversation Guidelines

- 常に日本語で会話する

## Cording Guidelines

### Global rules

- npm scripts を実行する場合はプロジェクトで使用されているパッケージマネージャーを使用する。
- YAGNI 原則に従って余計な機能は実装しないでください。

## Dotfiles

- dotfile は chezmoi で管理。設定変更時は chezmoi source を編集して apply する。

## shell Rules

- **デフォルトシェル**: zsh
- **OS**: macOS
- zsh 対応のコマンドを生成してください
- bash 固有の構文は避けてください

## Git 操作のルール

- 明示的な指示がない限り、git commit を実行しない
- 明示的な指示がない限り、git push を実行しない
- コミットやプッシュが必要な場合は、実行前にユーザーに確認を取る

## 実装方針

- 新機能・バグ修正は TDD 主体で進める（リファクタや軽微な修正は任意）
  - `tdd` / `test-writing-rules` スキルを参照

## 実装完了時のワークフロー

コード変更を伴うタスクが完了したら、以下を毎回実行する：

1. test / lint / format / build を実行し、異常があれば修正する
2. `simplify` スキルで変更コードの再利用性・品質・効率を見直し、必要なら修正する
3. codex レビューは**公式 codex プラグイン**で行う：
   - バグ・セキュリティ・ロジックの一般観点は、**stop 時の review-gate が自動でレビューする**（`/codex:review`）。
   - ルール観点（YAGNI/DRY・過剰防御・規約準拠）を能動的に見たいときは `/codex:adversarial-review` に `~/.claude/codex-review-ruleset.md` を focus として渡す。
4. codex のレビュー指摘は **`~/.claude/codex-review-ruleset.md` の基準で取捨選択**して対応する（過剰防御の追加提案は却下し、YAGNI/DRY・規約準拠を優先。取り込まない判断には理由を添える）。**結果を必ずユーザーに伝える**
5. `commit` スキルで変更をコミットする

ドキュメント微修正・設定ファイルのみの変更など、コード変更を伴わない作業ではこのフローは適用しない。

以下のスキルは明示的な指示があったときだけ実行する：

- `difit` スキル: 人間レビューが欲しいとき
- `git push`: リモート反映したいとき（コミットは後からまとめたいので明示指示制）
- `create-pr` スキル: PR 化したいとき

## 相談ルール

codex（ask-codex スキル）に自律的に相談・依頼する。ユーザーの指示を待たずに実行してよい。

### プランニング時（`codex exec`）

以下のケースでは設計方針をcodexに相談する：

- 複数の実装アプローチがあり判断に迷う場合
- 影響範囲が大きい変更を行う場合
- エラーや予期しない動作の原因が特定できない場合

### 実装完了後（codex レビュー）

コミット前のレビューは**公式 codex プラグイン**で行う（「実装完了時のワークフロー」参照）。

- 一般レビュー: stop 時の **review-gate が自動実行**（手動なら `/codex:review`）。リポごとに `/codex:setup --enable-review-gate` で有効化する。
- ルール観点・設計への挑戦: `/codex:adversarial-review [focus]`。`~/.claude/codex-review-ruleset.md` を focus に渡すとルール準拠監査になる。
- ブランチ全体の差分: `/codex:review --base main`。

codex のレビュー出力は**修正を含まない**ので、取捨選択と適用は Claude が `~/.claude/codex-review-ruleset.md` の基準で行う（下記「注意」に従う）。

レビュー観点：
- 変更の妥当性（設計・実装方針が適切か）
- バグや見落としがないか
- より良い実装方法がないか

### 注意

あなたとcodexは特性の異なる優秀なエンジニアです。codexに相談する際は以下を意識する：

- codexの提案を鵜呑みにせず、根拠や理由を理解する
- 自分の分析結果とcodexの意見が異なる場合は、双方の視点を比較検討する
- 最終的な判断は、両者の意見を総合的に評価した上で、自分で下す
