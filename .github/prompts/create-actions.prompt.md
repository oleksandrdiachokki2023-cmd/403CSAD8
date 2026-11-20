---
mode: agent
description: Створює GitHub Actions CI workflow із матрицею Ubuntu, Windows і macOS.
---

Використай skill `github-actions` з `.github/skills/github-actions/SKILL.md`, щоб створити `.github/workflows/ci.yml`.

Workflow має:

- запускатися на `push` і `pull_request`;
- використовувати `actions/checkout` та `actions/setup-python`;
- перевіряти Python-проєкт із `requirements.txt` і тестами через матрицю `ubuntu-latest`, `windows-latest`, `macos-latest`;
- створювати `.venv` на кожній ОС і запускати `bash ci.sh` на Ubuntu/macOS та `ci.bat` на Windows; команди мають працювати з кореня репозиторію;
- зберігати помилковий exit code і не приховувати збої.

Перевір наявні workflow перед редагуванням і не перезаписуй їх без потреби. Перевір YAML за допомогою наявного `actionlint` або доступного YAML-валідатора; якщо валідатор недоступний, явно повідом про це й виконай доступну перевірку структури. Не додавай секретів. У разі помилки покажи лог і зупинись.
