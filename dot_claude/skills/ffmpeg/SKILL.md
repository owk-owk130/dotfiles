---
name: ffmpeg
disable-model-invocation: true
description: 自然言語の指示からffmpegコマンドを生成・即実行する動画/音声処理スキル。
---

# ffmpeg スキル

自然言語の指示を理解し、適切なffmpegコマンドを生成・実行するスキル。

## 基本方針

1. ユーザーの指示から意図を読み取り、最適なffmpegコマンドを組み立てる
2. コマンドを生成したら即座に実行する（確認は不要）
3. 実行結果を簡潔に報告する

## コマンド生成のルール

### 出力ファイル名

- 入力ファイルと同じディレクトリに出力する
- ユーザーが出力ファイル名を指定しない場合、入力ファイル名をベースに意味のあるサフィックスを付ける
  - リサイズ: `input_720p.mp4`
  - トリミング: `input_trimmed.mp4`
  - 音声抽出: `input.mp3`
  - GIF変換: `input.gif`
  - 圧縮: `input_compressed.mp4`
  - 速度変更: `input_2x.mp4`
  - フォーマット変換: `input.{新フォーマット}`
- 出力先に同名ファイルが既に存在する場合、上書きしない。`_1`, `_2` などの連番サフィックスを付けて衝突を回避する

### 上書き防止

- `-y` フラグ（強制上書き）は使わない
- 出力先に同名ファイルがあるか事前に確認し、あれば別名にする

### 入力ファイルの確認

- コマンド実行前に入力ファイルが存在するか確認する
- ファイルが見つからない場合はユーザーに正しいパスを確認する
- ユーザーがファイル名だけ指定した場合、カレントディレクトリまたは直近の会話コンテキストからパスを推定する

### よく使うパターン

#### フォーマット変換
```bash
ffmpeg -i input.mov output.mp4
```

#### リサイズ（アスペクト比維持）
```bash
# 幅1280px、高さは自動（偶数に丸める）
ffmpeg -i input.mp4 -vf "scale=1280:-2" output_720p.mp4
```

#### トリミング（時間指定で切り出し）
```bash
# 開始10秒から30秒間
ffmpeg -i input.mp4 -ss 00:00:10 -t 00:00:30 -c copy output_trimmed.mp4
```

#### 音声抽出
```bash
ffmpeg -i input.mp4 -vn -acodec libmp3lame -q:a 2 output.mp3
```

#### GIF作成
```bash
# パレット生成→GIF変換の2パスで高品質に
ffmpeg -i input.mp4 -ss 10 -t 5 -vf "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" output.gif
```

#### 動画結合
```bash
# ファイルリストを作成して結合
echo "file 'input1.mp4'" > /tmp/ffmpeg_concat_list.txt
echo "file 'input2.mp4'" >> /tmp/ffmpeg_concat_list.txt
ffmpeg -f concat -safe 0 -i /tmp/ffmpeg_concat_list.txt -c copy output_merged.mp4
```

#### 圧縮（ファイルサイズ削減）
```bash
ffmpeg -i input.mp4 -c:v libx264 -crf 28 -preset medium -c:a aac -b:a 128k output_compressed.mp4
```

#### 速度変更
```bash
# 2倍速（映像 + 音声）
ffmpeg -i input.mp4 -vf "setpts=0.5*PTS" -af "atempo=2.0" output_2x.mp4
```

#### 音声除去
```bash
ffmpeg -i input.mp4 -an -c:v copy output_muted.mp4
```

#### サムネイル抽出
```bash
# 指定秒数のフレームを1枚抽出
ffmpeg -i input.mp4 -ss 00:00:05 -frames:v 1 thumbnail.jpg
```

#### クロップ（部分切り抜き）
```bash
# 中央から640x480を切り出す
ffmpeg -i input.mp4 -vf "crop=640:480" output_cropped.mp4
# 左上座標(100,50)から800x600を切り出す
ffmpeg -i input.mp4 -vf "crop=800:600:100:50" output_cropped.mp4
```

#### 回転・反転
```bash
# 時計回りに90度回転
ffmpeg -i input.mp4 -vf "transpose=1" output_rotated.mp4
# 左右反転
ffmpeg -i input.mp4 -vf "hflip" output_flipped.mp4
# 上下反転
ffmpeg -i input.mp4 -vf "vflip" output_flipped.mp4
# 180度回転
ffmpeg -i input.mp4 -vf "transpose=1,transpose=1" output_rotated180.mp4
```

#### ウォーターマーク/ロゴの重ね合わせ
```bash
# 右下に配置（10pxマージン）
ffmpeg -i input.mp4 -i logo.png -filter_complex "overlay=W-w-10:H-h-10" output_watermarked.mp4
```

#### テキスト（字幕）の焼き付け
```bash
ffmpeg -i input.mp4 -vf "drawtext=text='サンプル':fontsize=48:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2" output_text.mp4
```

#### 字幕の抽出・追加
```bash
# 字幕の抽出
ffmpeg -i input.mp4 -map 0:s:0 output.srt
# SRT字幕の追加（焼き付け）
ffmpeg -i input.mp4 -vf "subtitles=subtitle.srt" output_subtitled.mp4
```

#### ピクチャーインピクチャー
```bash
# メイン動画の右下に小窓（幅1/4）を配置
ffmpeg -i main.mp4 -i pip.mp4 -filter_complex "[1:v]scale=iw/4:-2[pip];[0:v][pip]overlay=W-w-10:H-h-10" output_pip.mp4
```

#### 複数動画のタイル並列表示
```bash
# 2x2グリッド
ffmpeg -i a.mp4 -i b.mp4 -i c.mp4 -i d.mp4 -filter_complex "[0:v][1:v][2:v][3:v]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0[v]" -map "[v]" output_grid.mp4
```

#### フェードイン/フェードアウト
```bash
# 映像: 最初の1秒フェードイン、最後の1秒フェードアウト（30秒の動画の場合）
ffmpeg -i input.mp4 -vf "fade=t=in:st=0:d=1,fade=t=out:st=29:d=1" -af "afade=t=in:st=0:d=1,afade=t=out:st=29:d=1" output_fade.mp4
```

#### 逆再生
```bash
ffmpeg -i input.mp4 -vf reverse -af areverse output_reversed.mp4
```

#### 色調補正・フィルター
```bash
# 明るさ・コントラスト・彩度の調整
ffmpeg -i input.mp4 -vf "eq=brightness=0.1:contrast=1.2:saturation=1.3" output_adjusted.mp4
# モノクロ化
ffmpeg -i input.mp4 -vf "hue=s=0" output_mono.mp4
```

#### 音量調整
```bash
# 音量を2倍に
ffmpeg -i input.mp4 -af "volume=2.0" output_loud.mp4
# 音量を正規化（ラウドネス基準）
ffmpeg -i input.mp4 -af "loudnorm" output_normalized.mp4
```

#### 音声の差し替え・追加
```bash
# 元の音声を別の音声に差し替え
ffmpeg -i input.mp4 -i new_audio.mp3 -c:v copy -map 0:v:0 -map 1:a:0 output_replaced.mp4
# BGMをミックス（元の音声を残す）
ffmpeg -i input.mp4 -i bgm.mp3 -filter_complex "[0:a][1:a]amix=inputs=2:duration=first[a]" -map 0:v -map "[a]" output_mixed.mp4
```

#### 連番画像から動画作成
```bash
# img001.png, img002.png, ... → 動画
ffmpeg -framerate 30 -i img%03d.png -c:v libx264 -pix_fmt yuv420p output.mp4
```

#### 動画から連番画像に書き出し
```bash
# 1秒あたり1フレーム抽出
ffmpeg -i input.mp4 -vf "fps=1" frame_%04d.png
```

#### フレームレート変更
```bash
ffmpeg -i input.mp4 -r 60 output_60fps.mp4
```

#### ビットレート指定エンコード
```bash
# 映像5Mbps、音声192kbps
ffmpeg -i input.mp4 -c:v libx264 -b:v 5M -c:a aac -b:a 192k output_bitrate.mp4
# 目標ファイルサイズから逆算する場合: ビットレート = (目標サイズMB × 8192) / 動画秒数 kbps
```

#### HLS（ストリーミング配信用）セグメント化
```bash
ffmpeg -i input.mp4 -c:v libx264 -c:a aac -f hls -hls_time 10 -hls_list_size 0 output.m3u8
```

#### 解像度プリセット

| 名称 | 解像度 | scale フィルタ |
|------|--------|---------------|
| 4K | 3840x2160 | `scale=3840:-2` |
| 1080p / FHD | 1920x1080 | `scale=1920:-2` |
| 720p / HD | 1280x720 | `scale=1280:-2` |
| 480p / SD | 854x480 | `scale=854:-2` |
| 360p | 640x360 | `scale=640:-2` |

## 実行時の注意

### プログレス表示
- 長時間かかる処理の場合、ffmpegの出力をそのまま流す
- タイムアウトは処理内容に応じて適切に設定する（大きなファイルは長めに）

### エラーハンドリング
- ffmpegがエラーを返した場合、エラーメッセージを読み取って原因を特定し、修正したコマンドで再試行する
- よくあるエラー:
  - コーデック未対応 → 別のコーデックを試す
  - 解像度が奇数 → `-2` で偶数に丸める
  - 入力ファイル破損 → ユーザーに報告

### 結果報告
処理完了後、以下を簡潔に報告する:
- 実行したコマンド
- 出力ファイルのパス
- 出力ファイルのサイズ
- 処理にかかった時間（長い場合）

## ファイル情報の取得

ユーザーが動画/音声の情報を知りたい場合は `ffprobe` を使う:
```bash
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4
```
