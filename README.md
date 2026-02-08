# mycloud-infra-template

OpenStack上で多様なインフラサービスをデプロイするためのTerraformテンプレート

## アーキテクチャ

### データベースクラスター
- **mongodb_cluster**: MongoDBレプリカセット（XFSボリューム、DNS自動設定）
- **tidb_cluster**: TiDB分散SQL（PD/TiDB/TiKV/TiFlash/TiFlash Controller構成）
- **mysql_cluster**: MySQLクラスタ
- **elasticsearch_cluster**: Elasticsearchクラスタ

### AI/ML推論サーバー
- **vllm**: 高効率LLM推論サーバー（GPUファン制御、電力制限調整、HuggingFace NFSキャッシュ）
- **ollama**: ローカルLLMサーバー（Dockerベース、Flash Attention、GPU対応）
- **comfyui**: 画像生成サーバー（NFS共有、PyTorch CUDA 1.29）

### データ処理・ワークフロー
- **hadoop_cluster**: Hadoop分散処理クラスタ
- **kubeflow_cluster**: MLワークフロープラットフォーム（Kubernetesベース）
- **n8n_docker**: ワークフローオートメーション
- **dify_docker**: AIアプリケーション構築プラットフォーム

### インフラ基盤
- **networking**: VPC、サブネット（10.10.0.0/16）、ルータ、DNSゾーン
- **bastion**: SSHジャンプホスト、セキュリティグループ

## ディレクトリ構造

```
.
├── environments/          # 環境別設定
│   ├── global/           # グローバル共通リソース
│   ├── stg/              # ステージング環境
│   └── prod/             # 本番環境
├── modules/              # 再利用可能なTerraformモジュール
│   ├── bastion/
│   ├── comfyui/
│   ├── docker_app/
│   ├── elasticsearch_cluster/
│   ├── hadoop_cluster/
│   ├── home_infra/
│   ├── kubeflow_cluster/
│   ├── mongodb_cluster/
│   ├── mysql_cluster/
│   ├── networking/
│   ├── ollama/
│   ├── ray-vllm/
│   ├── tidb_cluster/
│   ├── vllm/
│   └── vllm-multiple/
└── .devcontainer/        # VS Code Dev Container設定
```

## 開発環境

このプロジェクトはVS Code Dev Containerに対応しています。

### 必要な資格情報
- `~/.aws`: AWS証明書
- `~/.openstack`: OpenStack証明書（clouds.yaml）

### 拡張機能
- HashiCorp Terraform

## 主な機能

### GPU最適化
- GPUファン制御（温度ベースの自動調整）
- 電力消費制限設定
- NCCL P2P無効化オプション

### ストレージ
- XFSボリューム（データベース）
- NFS共有（HuggingFaceモデル、ComfyUI）
- OpenStack Cinderボリューム

### ネットワーク
- DNSレコード自動生成（SRVレコード含む）
- セキュリティグループ自動設定
- フローティングIP割り当て

## モジュール使用例

### MongoDBクラスタ
```
module "mongodb_cluster" {
  source           = "../../../modules/mongodb_cluster"
  environment_name = "stg"
  node_count       = 3
  replica_set_name = "rs0"
  data_volume_size = 100
}
```

### vLLMサーバー
```
module "vllm" {
  source              = "../../../modules/vllm"
  environment_name    = "stg"
  model_name          = "meta-llama/Llama-2-7b-chat-hf"
  gpu_count           = 4
  gpu_power_limit     = 300
}
```

## 環境変数

主要な環境変数（各モジュールのvariables.tfを参照）:
- `environment_name`: 環境名
- `project_id`: OpenStackプロジェクトID
- `image_id`: ソースイメージID
- `flavor_id`: フレーバーID
- `gpu_count`: GPU数
- `huggingface_hf_token`: HuggingFace認証トークン

## ライセンス

Copyright © 2024