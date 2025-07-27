# 🧪 Spomky PHP QA Docker Image

This repository provides a custom Docker image based on [`jakzal/phpqa`](https://github.com/jakzal/phpqa) with:

- ✅ Additional QA tools for PHP projects
- 🛠️ [Castor](https://github.com/jolicode/castor) pre-installed as a task runner

---

## 📦 Available on GitHub Container Registry

```bash
# Pull the image for your desired PHP version
docker pull ghcr.io/spomky-labs/phpqa:<version>
```

Replace `<version>` with one of the supported PHP versions below.

---

## 🔢 Supported PHP Versions

The following versions are available as tags:

| PHP Version | Tags |
|-------------|------|
| 8.2 | `8.2`, `8.2-amd64`, `8.2-arm64`, `8.2-<sha>`, `8.2-latest` (main branch only) |
| 8.3 | `8.3`, `8.3-amd64`, `8.3-arm64`, `8.3-<sha>`, `8.3-latest` (main branch only) |
| 8.4 | `8.4`, `8.4-amd64`, `8.4-arm64`, `8.4-<sha>`, `8.4-latest` (main branch only) |
| 8.5 | `8.5`, `8.5-amd64`, `8.5-arm64`, `8.5-<sha>` (build may fail, experimental) |

If a release is tagged (e.g. `8.4.1`), additional tags will be pushed:
- `8.4.1`, `8.4`, `8`

---

## 🧪 Usage Example

Run PHPUnit from the container:

```bash
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 phpunit
```

---

## 🛠️ Pre-installed tools

This image includes:

- PHP QA tools from [`jakzal/phpqa`](https://github.com/jakzal/phpqa)
- [Castor](https://github.com/jolicode/castor)
- Custom QA extensions and utilities

---

## 📄 License

This project is licensed under the MIT License.
