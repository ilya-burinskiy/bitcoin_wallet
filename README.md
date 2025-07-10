# Сборка
`docker compose build`
# Создание кошелька
`docker compose run bitcoin-wallet create`
# Получение баланса
`docker compose run bitcoin-wallet balance`
# Отправка биткоинов
`docker compose run bitcoin-wallet send --addr ADRESS --amount AMOUNT`\
AMOUNT в биткоинах (Например 0.00001).
