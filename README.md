# **Проект 2** — Маркетинговая аналитика и атрибуция трафика
**Стек:** PostgreSQL, Apache Superset (Preset), DBeaver, GitHub

🛠 Описание:
1. Подключился к маркетинговой PostgreSQL-базе (таблицы: sessions, leads, vk_ads, ya_ads) образовательной школы и реализовал модель атрибуции Last Paid Click — связал рекламные переходы с лидами и продажами через UTM-метки
2. Рассчитал витрину расходов с агрегацией по UTM-меткам: visitors_count, leads_count, purchases_count, revenue, total_cost — с правильной сортировкой null-значений и многоуровневой группировкой
3. Рассчитал ключевые маркетинговые метрики: CPU, CPL, CPPU, ROI — на уровне utm_source и детально по source / medium / campaign
4. Собрал дашборд в Apache Superset с интерактивными фильтрами по дате, utm_source, utm_medium, utm_campaign. [Посмотреть дашборд](https://1d811c51.us1a.app.preset.io/superset/dashboard/13/?native_filters_key=HsAjT_vrI4c).
5. Провёл анализ окупаемости каналов, оценил корреляцию между рекламными кампаниями и органическим трафиком, рассчитал время закрытия 90% лидов; оформил выводы в презентацию

## Что реализовано

### 1. Модель атрибуции Last Paid Click
Связал рекламные переходы с лидами и продажами через UTM-метки (`source`, `medium`, `campaign`, `content`).  
Платными считаются каналы: `cpc`, `cpm`, `cpa`, `youtube`, `cpp`, `tg`, `social`.

### 2. Витрина расходов
Агрегация по UTM-меткам с расчётом:

| Метрика | Описание |
|---|---|
| `visitors_count` | Количество визитов |
| `leads_count` | Количество лидов |
| `purchases_count` | Количество успешных сделок |
| `revenue` | Выручка с закрытых лидов |
| `total_cost` | Затраты на рекламу |

### 3. Маркетинговые метрики

| Метрика | Формула |
|---|---|
| `CPU` | `total_cost / visitors_count` |
| `CPL` | `total_cost / leads_count` |
| `CPPU` | `total_cost / purchases_count` |
| `ROI` | `(revenue - total_cost) / total_cost × 100%` |

Расчёт на двух уровнях детализации: по `utm_source` и по `source / medium / campaign`.

### 4. Дашборд и презентация
Интерактивный дашборд в Apache Superset с фильтрами по дате, `utm_source`, `utm_medium`, `utm_campaign`.  
Презентация включает анализ окупаемости каналов, корреляцию рекламы с органикой и время закрытия 90% лидов.

## Структура репозитория

| Файл | Описание |
|------|----------|
| `last_paid_click.sql` | SQL-запрос построения витрины атрибуции Last Paid Click |
| `last_paid_click.csv` | Топ-10 записей витрины атрибуции |
| `aggregate_last_paid_click.sql` | SQL-запрос агрегации данных по UTM-меткам с расчётом расходов на рекламу по модели атрибуции Last Paid Click |
| `aggregate_last_paid_click.csv` | Топ-15 записей агрегированной витрины расходов |
| `dashboard.sql` | Запросы для построения дашборда (последние два графика в дашборде) |
| `presentation.pdf` | Презентация с выводами и рекомендациями по рекламным каналам |