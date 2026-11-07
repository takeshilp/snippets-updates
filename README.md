# Сниппеты: релизы и установщик (Chrome / Edge, Windows)

[English version below](#english)

Сниппеты — небольшое бесплатное расширение для Chrome и Edge: вы печатаете короткое сокращение в поле ввода, и на его месте появляется готовый текст (шаблоны, формы, колесо сниппетов). Работает только на тех сайтах, которые вы сами укажете в настройках; на остальных ничего не делает. Бесплатно для некоммерческого использования.

Здесь лежат установщик, обновляющий скрипт и релизы. Интерфейс расширения на русском.

## Установка (Windows)

1. Нажмите Win+R (или откройте cmd) и выполните:

   ```
   powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/takeshilp/snippets-updates/main/install.ps1)"
   ```

2. Если расширение уже стоит, установщик найдёт его сам; ваши данные сохранятся. Если нет, он скачает расширение и покажет папку. Откройте `chrome://extensions` (или `edge://extensions`), включите **Режим разработчика**, нажмите **Загрузить распакованное расширение** и выберите эту папку.
3. Первый запуск: пока список сайтов пуст, расширение работает на всех сайтах. Чтобы ограничить его, добавьте нужные сайты: значок расширения → менеджер → ⚙ → «Сайты» или правый клик на странице → «Сниппеты» → «Добавить сайт в список».

## Как работают обновления

- Скрипт проверяет новую версию раз в час и при входе в систему (задача планировщика `SnippetsUpdater`, без прав администратора, без окон).
- Скачанная версия ждёт рядом с папкой расширения. Установка происходит, когда браузер закрыт около 30 секунд; пока она ждёт, об этом написано во всплывающем окне расширения. Запустите браузер снова: версия включится сама, ничего нажимать не нужно.
- Ваши сниппеты и настройки хранятся в браузере и при обновлении сохраняются.
- Журнал: `%LOCALAPPDATA%\SnippetsUpdater\update.log`.
- Если в Edge включено «Ускорение запуска», процесс браузера может не закрываться: выключите его в `edge://settings/system`. В Chrome то же делает «Продолжать работу фоновых приложений» в `chrome://settings/system`.

## Удаление

1. `powershell -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\SnippetsUpdater\update.ps1" -Uninstall` убирает задачу и скрипт.
2. Затем нажмите **Удалить** на карточке расширения в `chrome://extensions`. Это удаляет и ваши сниппеты: сначала сделайте резервную копию (менеджер → Экспорт → Резервная копия JSON).

## Откат вручную

Закройте браузер, затем переименуйте папку расширения `<папка>` в `<папка>.new`, а `<папка>.old` в `<папка>`. Новые версии ставятся только вперёд: при следующем обновлении установится более новая версия.

## Честно о главном

- Код минифицирован, но не секретен: браузер его получает, любой может прочитать.
- Скрипты расширения загружаются на всех сайтах, но вне вашего списка ничего не делают (читают только ваш список сайтов).
- С версии 0.17.0 релизы не подписываются: обновлятор проверяет только контрольную сумму архива (защита от битой загрузки). Тот, кто управляет этим репозиторием, может выпустить любую версию.
- **Обновление с 0.16:** установленный обновлятор 0.16 принимает только подписанные релизы, поэтому один раз выполните команду установки ещё раз: она найдёт расширение, заменит обновлятор и сохранит ваши данные. Дальше обновления снова идут сами.
- Корпоративные политики могут запрещать PowerShell или нераспакованные расширения.
- Лицензия: PolyForm Noncommercial 1.0.0, см. `LICENSE`.

---

<a id="english"></a>

# Snippets: releases and installer (Chrome / Edge, Windows)

Snippets is a small, free extension for Chrome and Edge: type a short abbreviation in a text field and it turns into ready text (templates, forms, a snippet wheel). It works only on the sites you list yourself in its settings and does nothing elsewhere. Free for non-commercial use.

This repository holds the installer, the updater script and the releases. The extension interface is in Russian.

## Install (Windows)

1. Press Win+R (or open cmd) and run:

   ```
   powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/takeshilp/snippets-updates/main/install.ps1)"
   ```

2. If the extension is already installed, the installer finds it and keeps your data. If not, it downloads the extension and prints a folder. Open `chrome://extensions` (or `edge://extensions`), turn on **Developer mode**, click **Load unpacked** and pick that folder.
3. First run: while the site list is empty the extension works on every site. To limit it, add your sites: extension icon → manager → ⚙ → «Сайты», or right click on the page → «Сниппеты» → «Добавить сайт в список».

## How updates work

- The script checks for a new version hourly and at logon (scheduled task `SnippetsUpdater`, no admin rights, no windows).
- A downloaded version waits next to the extension folder. It is installed once the browser has been closed for about 30 seconds; while it waits, the extension popup says so. Start the browser again: the version switches on by itself, nothing to click.
- Your snippets and settings live in the browser and are kept through updates.
- Log: `%LOCALAPPDATA%\SnippetsUpdater\update.log`.
- With Edge «Startup boost» on, the browser process may never close: turn it off in `edge://settings/system`. In Chrome the same is «Continue running background apps» in `chrome://settings/system`.

## Remove

1. `powershell -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\SnippetsUpdater\update.ps1" -Uninstall` removes the task and the script.
2. Then click **Remove** on the extension card at `chrome://extensions`. That deletes your snippets too: make a backup first (manager → Экспорт → Резервная копия JSON).

## Roll back by hand

Close the browser, then rename the extension folder `<folder>` to `<folder>.new` and `<folder>.old` to `<folder>`. Versions only move forward: the next update installs a newer version.

## Honest notes

- The code is minified, not secret: the browser receives it, anyone can read it.
- The extension scripts load on every site but do nothing outside your list (they read only your site list).
- Since 0.17.0 releases are not signed: the updater checks only the archive's checksum (a broken download). Whoever controls this repository can ship any version.
- **Updating from 0.16:** the 0.16 updater accepts signed releases only, so run the install command once more: it finds the extension, replaces the updater and keeps your data. After that updates come by themselves again.
- Corporate policies may block PowerShell or unpacked extensions.
- License: PolyForm Noncommercial 1.0.0, see `LICENSE`.
