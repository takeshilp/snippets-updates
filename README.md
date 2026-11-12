# Сниппеты: релизы (Chrome / Edge)

[English version below](#english)

Сниппеты — небольшое бесплатное расширение для Chrome и Edge: вы печатаете короткое сокращение в поле ввода, и на его месте появляется готовый текст (шаблоны, формы, колесо сниппетов). Работает только на тех сайтах, которые вы сами укажете в настройках; на остальных ничего не делает. Бесплатно для некоммерческого использования.

Здесь лежат релизы: архив `snippets-<версия>.zip` в каждом. Интерфейс расширения на русском.

## Установка

1. Скачайте `snippets-<версия>.zip` из последнего релиза (Releases справа).
2. Распакуйте его в постоянную папку, например `%LOCALAPPDATA%\Snippets\extension`. Не переносите её потом: другая папка — это другое расширение, без ваших сниппетов.
3. Откройте `chrome://extensions` (или `edge://extensions`), включите **Режим разработчика**, нажмите **Загрузить распакованное расширение** и выберите эту папку.
4. Первый запуск: пока список сайтов пуст, расширение работает на всех сайтах. Чтобы ограничить его, добавьте нужные сайты: значок расширения → менеджер → ⚙ → «Сайты» или правый клик на странице → «Сниппеты» → «Добавить сайт в список».

## Обновление

Обновления ставятся вручную, расширение само их не ищет и о них не сообщает.

1. Скачайте архив новой версии.
2. Полностью закройте браузер (все окна). В Edge выключите «Ускорение запуска» (`edge://settings/system`), в Chrome — «Продолжать работу фоновых приложений» (`chrome://settings/system`), иначе браузер остаётся запущенным.
3. Удалите содержимое папки расширения и распакуйте в неё новый архив. Папка должна быть та же.
4. Запустите браузер: новая версия включится сама. Сниппеты и настройки хранятся в браузере и сохраняются.

**Если у вас стоял обновлятор** (версии 0.34 и раньше ставились командой `install.ps1`), уберите его один раз:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\SnippetsUpdater\update.ps1" -Uninstall
```

Это убирает задачу планировщика `SnippetsUpdater` и его папку; расширение и данные остаются.

## Удаление

Нажмите **Удалить** на карточке расширения в `chrome://extensions`. Это удаляет и ваши сниппеты: сначала сделайте резервную копию (менеджер → Экспорт → Резервная копия JSON).

## Честно о главном

- Код минифицирован, но не секретен: браузер его получает, любой может прочитать.
- Скрипты расширения загружаются на всех сайтах, но вне вашего списка ничего не делают (читают только ваш список сайтов).
- Расширение не делает запросов в интернет.
- Релизы не подписываются: скачивайте архив только отсюда.
- Корпоративные политики могут запрещать нераспакованные расширения.
- Лицензия: PolyForm Noncommercial 1.0.0, см. `LICENSE`.

---

<a id="english"></a>

# Snippets: releases (Chrome / Edge)

Snippets is a small, free extension for Chrome and Edge: type a short abbreviation in a text field and it turns into ready text (templates, forms, a snippet wheel). It works only on the sites you list yourself in its settings and does nothing elsewhere. Free for non-commercial use.

This repository holds the releases: each has a `snippets-<version>.zip`. The extension interface is in Russian.

## Install

1. Download `snippets-<version>.zip` from the latest release (Releases on the right).
2. Extract it into a permanent folder, for example `%LOCALAPPDATA%\Snippets\extension`. Do not move it later: another folder is another extension, without your snippets.
3. Open `chrome://extensions` (or `edge://extensions`), turn on **Developer mode**, click **Load unpacked** and pick that folder.
4. First run: while the site list is empty the extension works on every site. To limit it, add your sites: extension icon → manager → ⚙ → «Сайты», or right click on the page → «Сниппеты» → «Добавить сайт в список».

## Update

Updates are installed by hand; the extension neither looks for them nor announces them.

1. Download the new version's archive.
2. Close the browser completely (every window). In Edge turn off «Startup boost» (`edge://settings/system`), in Chrome «Continue running background apps» (`chrome://settings/system`), or the browser keeps running.
3. Delete the contents of the extension folder and extract the new archive into it. It must be the same folder.
4. Start the browser: the new version switches on by itself. Your snippets and settings live in the browser and are kept.

**If you had the updater** (versions 0.34 and earlier were installed with `install.ps1`), remove it once:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\SnippetsUpdater\update.ps1" -Uninstall
```

That removes the scheduled task `SnippetsUpdater` and its folder; the extension and your data stay.

## Remove

Click **Remove** on the extension card at `chrome://extensions`. That deletes your snippets too: make a backup first (manager → Экспорт → Резервная копия JSON).

## Honest notes

- The code is minified, not secret: the browser receives it, anyone can read it.
- The extension scripts load on every site but do nothing outside your list (they read only your site list).
- The extension makes no requests to the internet.
- Releases are not signed: download the archive only from here.
- Corporate policies may block unpacked extensions.
- License: PolyForm Noncommercial 1.0.0, see `LICENSE`.
