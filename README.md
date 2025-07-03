# Сборка образа
`docker build -t bitcoin_wallet .`
# Запуск контейнера
`docker run --name bitcoin_wallet --rm -d -v $(pwd):/usr/src/bitcoin_wallet bitcoin_wallet:latest`
# Запуск терминала в контейнере
`docker exec -it bitcoin_wallet bash`
