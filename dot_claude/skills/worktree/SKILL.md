---
name: worktree
description: >
  別 issue や別タスクを git worktree + 別 cmux ワークスペース + 別 Claude セッションで並行して進められるようにする。
  ブランチ作成・worktree 作成・cmux で新ワークスペース起動・Claude を初期プロンプト付きで spawn まで一括で行う。
  Use when: (1) /worktree コマンドを実行した場合,
  (2) 「別セッションで実装」「並行で進めたい」「裏で進めて」「別の worktree で」等の要望があった場合,
  (3) 進行中の作業を止めずに別タスクに着手したい場合。
---

# Worktree

別タスク（典型的には別 issue）を**別 cmux ワークスペース・別 Claude セッション・別 worktree** で独立に進めるための skill。

メインの作業を止めずに、もう 1 つの作業を裏で走らせるのが目的。複数アプローチの比較ではなく、**並行作業の起ち上げ**に特化する。

## 引数

| Args | Action |
|------|--------|
| `<お題テキスト>` | テキストからブランチ名を生成して worktree を作る |
| `#123` | GitHub issue #123 を取得して、タイトルから worktree を作る |
| `issue #45` | 同上 |
| `#123 #124 #125` | 複数 issue を一気に起ち上げる |

## 全体フロー

```
入力（お題 or issue 番号）
  ↓
[1] 入力解析       - お題テキスト or issue 番号を判別
  ↓
[2] issue 取得     - issue 番号なら gh で情報取得
  ↓
[3] ブランチ名生成 - branch-start と同じ命名規則
  ↓
[4] worktree 作成  - git worktree add で新ディレクトリ + 新ブランチ
  ↓
[5] cmux で spawn  - 新ワークスペースを開いて claude を起動
  ↓
[6] 報告          - 起ち上げ結果をメインの会話に返す
```

複数 issue が渡された場合は [3]〜[5] を issue ごとに繰り返す。

## なぜこの構成か

- **完全独立**: 別 Claude プロセスなので、メインのセッションを閉じても作業が続く。コンテキストも完全に分離。
- **cmux ペイン**: 各タスクのセッションを目視で行き来できる。困ったら覗ける。
- **issue ごとに 1 セッション**: 1 ペイン = 1 issue という対応関係が明確なので、頭の中で迷子にならない。

## 手順

### 1. 前提チェック

```bash
# git リポジトリか
git rev-parse --is-inside-work-tree
# cmux が動いているか（CLI が叩ければ OK）
cmux ping
# claude が PATH にあるか
which claude
```

どれか欠けていればその旨を伝えて中止する。

### 2. 入力解析

入力を空白で分割し、各トークンを以下のように判別する:

- `#123` または `issue #123` → issue 番号として扱う
- それ以外のテキスト → お題テキストとして扱う（複数トークンはまとめて 1 つのお題）

複数 issue 番号が並んでいたら、それぞれ独立に処理する。

### 3. issue 取得（issue 番号の場合）

```bash
gh issue view <number> --json number,title,body,labels
```

取得できなければエラー報告して該当 issue だけスキップ（他の issue があれば続行）。

### 4. ブランチ名生成

`branch-start` スキルと同じ命名規則を使う:

- 形式: `{type}/{slug}` または `{type}/{number}-{slug}`
- type: `feat / fix / refactor / docs / chore / test / perf` から内容に応じて選ぶ
- slug: 英語ケバブケース、3〜5 単語程度
- 日本語のお題は英語に変換

**判定の根拠**:

- issue の場合: タイトルとラベルから判断
- テキストの場合: 内容から判断

### 5. worktree 作成

#### 5-1. ベースブランチを最新化

```bash
BASE_BRANCH=$(git remote show origin | grep 'HEAD branch' | awk '{print $NF}')
git fetch origin "$BASE_BRANCH"
```

worktree を作るだけなので、現在のブランチは切り替えない（メイン側の作業を壊さない）。

#### 5-2. worktree のパスを決める

リポジトリのルート名を取り、その隣に `<repo>-<slug>` のディレクトリを作る:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")
WORKTREE_PATH="$(dirname "$REPO_ROOT")/${REPO_NAME}-${SLUG}"
```

既に存在する場合は末尾に `-2`, `-3` を付けて衝突回避。

#### 5-3. worktree + ブランチを作る

```bash
git worktree add -b "${BRANCH_NAME}" "${WORKTREE_PATH}" "origin/${BASE_BRANCH}"
```

`origin/<base>` から切ることで、ローカルの中途半端な状態に影響されない。

### 6. cmux で新ワークスペースを起動

#### 6-1. 初期プロンプトを組み立てる

issue の場合:

```
issue #<番号> を実装してください。

## タイトル
<title>

## 本文
<body>

## 進め方
- CLAUDE.md の実装方針に従う（TDD 主体、test/lint/format/build 実行、codex review、commit スキル）
- 詰まったら破壊的操作で誤魔化さず、原因を明示する
- 完了したら commit まで進める（push と PR 作成は明示指示があるまで保留）
```

お題テキストの場合:

```
以下のタスクを実装してください。

## お題
<お題テキスト>

## 進め方
（issue と同じ）
```

#### 6-2. cmux で起動

```bash
cmux new-workspace \
  --cwd "${WORKTREE_PATH}" \
  --command "claude $(printf '%q' "${INITIAL_PROMPT}")"
```

`printf '%q'` でシェルエスケープを掛けて、改行やクォートを含むプロンプトでも安全に渡す。

戻り値からワークスペース ref を拾っておく（後の報告で使う）。

### 7. メイン会話への報告

各起動について以下を報告する:

```markdown
## 起ち上げ完了

| 項目 | 値 |
|------|----|
| タスク | <issue タイトル or お題の冒頭> |
| ブランチ | wt/feat/123-add-foo |
| worktree | /Users/.../repo-add-foo |
| cmux ワークスペース | workspace:5 |

該当の cmux ペインで Claude が起動し、初期プロンプトを受け取った状態です。
```

複数 issue を一気に処理した場合は、表に行を増やす。

## 重要なルール

1. **メインのブランチを切り替えない**: worktree を作るだけ。今いるブランチや作業中のファイルには手を出さない。
2. **既存 worktree を勝手に消さない**: パス衝突したらサフィックスを付けて回避。`git worktree remove --force` は明示指示なしには使わない。
3. **新セッション内の Claude の振る舞いはこの skill の責務外**: 子セッションが何をするかは初期プロンプトで誘導するだけ。メイン側は spawn したら手を離す。
4. **CLAUDE.md の実装方針を初期プロンプトに必ず含める**: TDD・test/lint・commit スキルなどが新セッションでも引き継がれるように。
5. **push と PR は子セッションでも明示指示があるまでやらない**: CLAUDE.md のルール通り。

## エッジケース

- **git リポジトリでない**: 中止し、その旨を伝える。
- **cmux が動いていない**: `cmux ping` で確認し、起動を促す。
- **既存ブランチ名と衝突**: ブランチ名の末尾に `-2`, `-3` を付けて再試行。
- **issue が private repo で gh 認証切れ**: 認証エラーを表示してその issue だけスキップ。
- **お題が短すぎ・曖昧すぎ**: spawn 自体は実行する（子セッションで深掘りすればよい）。ただし slug が極端に短くなる場合は適当な fallback（例: `task-<timestamp>`）を使う。
- **`claude` がカスタムエイリアスや mise 経由**: `which claude` で実体パスを確認し、フルパスで渡す。

## 子セッションでよく使う後続コマンド

skill 本体では実行しないが、ユーザーに参考として示してもよい:

- 子セッションでの作業確認: cmux のペインに移動して目視
- worktree 一覧: `git worktree list`
- worktree 削除: `git worktree remove <path>` （マージ済みなら）
- ブランチ削除: `git branch -d <branch>` （マージ済みなら）
