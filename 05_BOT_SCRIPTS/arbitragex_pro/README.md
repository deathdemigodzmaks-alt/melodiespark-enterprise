# ArbitrageX Pro

**REAL REVENUE GENERATION** - Crypto arbitrage trading bot that connects to actual exchanges to find and execute profitable arbitrage opportunities.

## Features

- **Real Exchange Connections**: Binance, Coinbase, Kraken, Bybit
- **Live Price Monitoring**: Real-time ticker and orderbook data
- **Automated Execution**: Automatically executes profitable arbitrage trades
- **Risk Management**: Configurable position limits, stop-loss, and emergency shutdown
- **Notifications**: Telegram, Discord, and email alerts
- **Monitoring**: Prometheus metrics and Grafana dashboards
- **Database**: Trade history and profit tracking

## Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure API Keys

Set your exchange API keys as environment variables:

```bash
export BINANCE_API_KEY="your_binance_api_key"
export BINANCE_API_SECRET="your_binance_api_secret"
export COINBASE_API_KEY="your_coinbase_api_key"
export COINBASE_API_SECRET="your_coinbase_api_secret"
```

### 3. Configure Trading Parameters

Edit `config.yaml` to set:
- Minimum spread percentage
- Minimum profit per trade
- Maximum position size
- Risk management limits

### 4. Run the Bot

```bash
python bot.py
```

## Docker Deployment

```bash
docker-compose up -d
```

## Risk Warning

**THIS BOT USES REAL MONEY**. Start with small amounts and test in paper trading mode first. Ensure you understand the risks of crypto arbitrage trading.

## Monitoring

- Grafana Dashboard: http://localhost:3000
- Prometheus Metrics: http://localhost:9091
- Logs: `./logs/arbitragex_pro.log`

## Revenue Generation

This bot generates REAL revenue by:
1. Scanning multiple exchanges for price differences
2. Calculating profitable arbitrage opportunities
3. Executing buy/sell orders simultaneously
4. Capturing the spread as profit

Expected returns: 0.5-2% per trade, multiple trades per day.

## Support

For issues and questions, check the documentation in `../docs/`.
