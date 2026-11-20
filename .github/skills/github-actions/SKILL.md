---
name: github-actions
description: Створює GitHub Actions workflow для pytest із матрицею Ubuntu, Windows і macOS.
---

# GitHub Actions

## Коли використовувати

Використовуй цей skill, коли потрібно автоматично запускати Python-тести в GitHub Actions на Linux, Windows і macOS.

## Вхідні дані

- Корінь репозиторію та його Python-версія.
- `requirements.txt` і тести, створені skill `build-and-test`.
- `ci.sh` для Linux/macOS та `ci.bat` для Windows, якщо workflow має запускати спільні CI-скрипти.

Перевір наявний `.github/workflows/` і не перезаписуй наявні workflow без потреби. Якщо версію Python не задано в проєкті, використовуй Python 3.

## Що створює

Файл `.github/workflows/ci.yml`, який:

- запускається на `push` і `pull_request`;
- використовує `actions/checkout` та `actions/setup-python`;
- задає матрицю `ubuntu-latest`, `windows-latest`, `macos-latest`;
- створює `.venv` для кожного runner-а;
- запускає відповідний скрипт: `bash ci.sh` на Ubuntu/macOS та `ci.bat` на Windows; ці скрипти встановлюють залежності з `requirements.txt` і запускають `pytest`.

Кроки мають працювати в корені репозиторію. Зберігай назви runner-ів саме у форматі GitHub Actions (`ubuntu-latest`, `windows-latest`, `macos-latest`). Не додавай секретів у YAML або журнали workflow.

## Як перевірити

1. Переконайся, що `.github/workflows/ci.yml` є валідним YAML і містить усі три runner-и.
2. Перевір локально команди відповідної ОС через `ci.sh` або `ci.bat`.
3. Після push або створення pull request перевір вкладку **Actions** у GitHub: усі три матричні job-и мають завершитися успішно.

## Якщо виникла помилка

- Якщо workflow не запускається, перевір шлях і назву файлу (`.github/workflows/ci.yml`), YAML-відступи й тригери `push`/`pull_request`.
- Якщо один runner падає, використовуй його логи, щоб визначити платформозалежну команду чи залежність; не вимикай цей runner для приховування проблеми.
- Якщо не знайдено requirements або CI-скрипт, звір шляхи з коренем репозиторію та результатом skill `build-and-test`.
- Після виправлення повторно запусти workflow і повідом про будь-який job, який і далі не проходить.
