# Таблицы
`users`
| Название | Тип | Description |
|----------|-----|-------------|
| `id` | int | айди пользователя|
| `email` | str | почта пользователя|

`crypto_wallets`
| Название | Тип | Description |
|----------|-----|-------------|
| `id` | int | айди кошелька |
| `user_id` | int | айди юзера |
| `balance` | int | баланс кошелька |
| `chain` | str | тип сети |
| `addr` | str | адрес кошелька |

`exchange_orders`
| Название | Тип | Description |
|----------|-----|-------------|
| `id` | int | айди обмена  |
| `status` | int | статус обмена (создан, выполнен, отменен) |
| `value` | int | сумма обмена |
| `source_currency` | str | исходная валюта |
| `target_currency` | str | целевая валюта |
| `exchange_rate` | float | курс валют на момент заказа |
| `exchange_fee` | float | fee которую берем за услугу |
| `network_fee` | int | fee майнерам |
| `deposit_crypto_wallet_id` | int | айди криптокошелька отправителя |
| `receive_crypto_wallet_id` | int | айди криптокошелька получателя |
| `created_at` | datetime | время создания |

`transactions`
| Название | Тип | Description |
|----------|-----|-------------|
| `id` | int | айди транзакции в самом обменнике |
| `currency` | str | валюта |
| `value` | int | сумма |
| `direction` | str | входящая/выходящая |
| `txid` | str | id крипто-транзакции |
| `confirmed` | bool | подтверждена ли |
| `exchange_id` | int | айди обмена |
| `created_at` | datetime | время создания |
| `confirmed_at` | datetime | время подтверждения |

# АПИ
* `GET /admin/exchange_orders` - получить список всех заказов\
  В параметрах можно указать фильтры (например по пользователю, статусу, валютам и т.д.)\
  В ответе отдаем
  - `id`
  - `status` - статус заказа
  - `value` - значение исходящей валюты
  - `source_currency` - тип исходящей валюты
  - `target_currency` - тип целевой валюты
  - `exchange_rate`
  - `network_fee`
  - `exchange_fee`
  - `receive_crypto_wallet_addr` - адрес кошелька получателя
  - `created_at`
* `GET /admin/crypto_wallets` - посмотреть баланс всех кошельков\
  В параметрах можно указать фильтры (например по пользователю, сети и т.д.)\
  В ответе отдаем
  - `id`
  - `user_id`
  - `balance`
  - `chain`
  - `addr`
* `POST /exchange_orders` - создать заказ\
  В теле запроса передаем
  - `value`
  - `source_currency`
  - `target_currency`
  - `email`\
  Отвечаем 201 и отдаем id заказа (если все ок)
* `GET /exchange_orders/{id}` - информация по заказу\
  В параметрах 
  - `id` - id заказа 
  В ответе 
  - `id`
  - `status` - статус заказа
  - `source_currency_value` - значение исходящей валюты
  - `source_currency` - тип исходящей валюты
  - `target_currency_value` - значение целевой валюты
  - `target_currency` - тип целевой валюты
  - `network_fee`
  - `exchange_fee`
  - `exchange_rate`
  - `receive_crypto_wallet_addr` - адрес кошелька получателя
  - `created_at`
