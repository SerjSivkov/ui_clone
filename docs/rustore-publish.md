# Публикация релиза в RuStore через GitHub Actions

По одобрению в UI («кнопка») workflow `.github/workflows/rustore-publish.yml`
создаёт новую версию в RuStore по git-тегу, загружает AAB и отправляет её
на модерацию.

Скрипт: [`bin/ci/rustore_publish.sh`](../bin/ci/rustore_publish.sh)
Документация API: [Загрузка и публикация приложений](https://www.rustore.ru/help/work-with-rustore-api/api-upload-publication-app)

Связанные файлы:

| Файл | Назначение |
|------|------------|
| `.github/workflows/rustore-publish.yml` | Сборка AAB по тегу + публикация с одобрением |
| `bin/ci/rustore_publish.sh` | Auth → черновик → AAB → модерация (RuStore API) |
| `docs/release-build.md` | Локальная сборка релиза и git-тег |

---

## 1. Как это работает

```
git tag v1.1.1 → push
   └─ Actions: workflow "RuStore publish"
        build-android:  Flutter + подпись keystore → appbundle
                        → dist/android/UIClone-android-v1.1.1.aab (artifact)
        publish-rustore: environment `rustore` → ждёт одобрения (кнопка)
             1. POST /public/auth               — токен (RSA-подпись, TTL 15 мин)
             2. GET  …/version                  — проверка активной версии,
                                                  удаление старого черновика
             3. POST …/version                  — черновик версии по тегу
             4. POST …/version/{id}/aab         — загрузка AAB
             5. POST …/version/{id}/commit      — на модерацию
```

- `whatsNew` берётся из секции `## X.Y.Z` в `CHANGELOG.md`; версия и
  `versionCode` — из самого AAB, поэтому тег должен совпадать с `pubspec.yaml`
  (`dart run release.dart` ставит тег на тот же коммит, что и `version:`).
- `publishType=INSTANTLY` — после модерации версия публикуется сама.

## 2. Настройка (один раз)

### 2.1. Одобрение = «кнопка»

**Settings → Environments → Create environment → имя `rustore` → Required
reviewers** → добавить себя. Пока одобрения нет, job `publish-rustore` стоит
в очереди; одобрить: вкладка Actions → воркфлоу → *Review deployments*.

### 2.2. Ключ RuStore (base64)

1. [RuStore Консоль](https://www.rustore.ru/developer) → **Компания/Разработчик →
   API RuStore → Создать ключ** (роль Владелец/Администратор): выбрать
   приложение **UI Clone** (или «Все приложения») и методы группы
   **«Загрузка и публикация приложений»** — иначе вызовы публикации ответят
   `403 This user does not have rights…`. Копируй приватный ключ сразу
   (показывается один раз) и id ключа.
2. Закодируй ключ: `base64 -i key.pem | tr -d '\n'` (или `base64 < key.pem`).

### 2.3. Secrets GitHub

**Settings → Secrets and variables → Actions:**

| Secret | Содержимое |
|--------|-----------|
| `RUSTORE_KEY_ID` | id ключа API из Консоли |
| `RUSTORE_KEY_BASE64` | base64 приватного ключа (одна строка) |
| `KEYSTORE_BASE64` | base64 `android/app/keystore.jks` (подпись AAB) |
| `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS` | из `android/key.properties.example` (например `upload`) |

Опциональные env воркфлоу: `RUSTORE_PACKAGE_NAME` (`com.mobileway.ui_clone`),
`ARTIFACT_PREFIX` (`UIClone`), `RUSTORE_PUBLISH_TYPE` (`INSTANTLY` |
`MANUAL`), `RUSTORE_PRIORITY_UPDATE`.

## 3. Запуск

```bash
dart run release.dart   # версия + CHANGELOG + коммит + тег v… → push
```

Дальше: Actions → **RuStore publish** → сборка пройдёт сама → на job
`publish-rustore` нажать **Review deployments → Approve and deploy**.
Повторный запуск безопасен: существующий черновик удаляется и создаётся заново.

Локальная проверка без CI:

```bash
CI_COMMIT_TAG=v1.1.1 \
RUSTORE_KEY_ID=12345 RUSTORE_KEY_BASE64="$(base64 -i key.pem | tr -d '\n')" \
./bin/ci/rustore_publish.sh
```

## 4. Ограничения RuStore API

- **Нужна ≥1 активная версия приложения** — без неё API не создаёт черновик
  (`Not found active version…`); первую версию публикуй вручную через
  RuStore Консоль (при отказе модератора — исправь и переотправь).
- **Один черновик** на приложение — job удаляет старый; версия в модерации
  блокирует публикацию (ждать).
- `versionCode` нового AAB должен быть больше активной версии; один `.aab`
  на версию (≤5 ГБ); токен живёт 15 минут.

## 5. Частые ошибки

| Сообщение | Причина / действие |
|-----------|--------------------|
| `403 This user does not have rights…` | ключ без методов «Загрузка и публикация приложений» — пересоздай ключ, обнови secrets |
| `Not found active version…` | нет активной версии — первая публикация вручную в Консоли |
| `Secret KEYSTORE_BASE64 is not set` | не добавлены секреты подписи (п. 2.3) |
| `Range timestamp not valid` | часы раннера расходятся с RuStore >60 с (NTP) |
