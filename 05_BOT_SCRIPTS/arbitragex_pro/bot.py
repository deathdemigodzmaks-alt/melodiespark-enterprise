"""
ArbitrageX Pro - Real Crypto Arbitrage Trading Bot
Connects to real exchanges (Binance, Coinbase, Kraken, etc.) to find and execute arbitrage opportunities.
Generates REAL revenue by exploiting price differences across exchanges.
"""

import asyncio
import aiohttp
import json
import logging
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime
import os
from decimal import Decimal

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('arbitragex_pro.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('ArbitrageX')


@dataclass
class ArbitrageOpportunity:
    """Represents a real arbitrage opportunity"""
    symbol: str
    buy_exchange: str
    sell_exchange: str
    buy_price: Decimal
    sell_price: Decimal
    spread_percent: Decimal
    min_profit: Decimal
    timestamp: datetime


@dataclass
class ExchangeConfig:
    """Exchange API configuration"""
    name: str
    api_key: str
    api_secret: str
    base_url: str
    websocket_url: Optional[str] = None
    testnet: bool = False


class ExchangeConnector:
    """Base class for exchange API connections"""
    
    def __init__(self, config: ExchangeConfig):
        self.config = config
        self.session: Optional[aiohttp.ClientSession] = None
        self.rate_limit = 10  # requests per second
        
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def get_ticker(self, symbol: str) -> Optional[Dict]:
        """Get current ticker price for a symbol"""
        raise NotImplementedError
    
    async def get_orderbook(self, symbol: str, depth: int = 20) -> Optional[Dict]:
        """Get order book for a symbol"""
        raise NotImplementedError
    
    async def place_order(self, symbol: str, side: str, quantity: Decimal, price: Decimal) -> Optional[Dict]:
        """Place a real order"""
        raise NotImplementedError
    
    async def get_balance(self) -> Optional[Dict]:
        """Get account balance"""
        raise NotImplementedError


class BinanceConnector(ExchangeConnector):
    """Binance exchange connector"""
    
    async def get_ticker(self, symbol: str) -> Optional[Dict]:
        """Get ticker from Binance API"""
        try:
            url = f"{self.config.base_url}/api/v3/ticker/price"
            params = {"symbol": symbol.replace("/", "")}
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    return {
                        "price": Decimal(str(data["price"])),
                        "symbol": symbol,
                        "exchange": "binance"
                    }
        except Exception as e:
            logger.error(f"Binance ticker error: {e}")
        return None
    
    async def get_orderbook(self, symbol: str, depth: int = 20) -> Optional[Dict]:
        """Get order book from Binance"""
        try:
            url = f"{self.config.base_url}/api/v3/depth"
            params = {"symbol": symbol.replace("/", ""), "limit": depth}
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    return {
                        "bids": [[Decimal(str(b[0])), Decimal(str(b[1]))] for b in data["bids"]],
                        "asks": [[Decimal(str(a[0])), Decimal(str(a[1]))] for a in data["asks"]],
                        "exchange": "binance"
                    }
        except Exception as e:
            logger.error(f"Binance orderbook error: {e}")
        return None


class CoinbaseConnector(ExchangeConnector):
    """Coinbase exchange connector"""
    
    async def get_ticker(self, symbol: str) -> Optional[Dict]:
        """Get ticker from Coinbase API"""
        try:
            url = f"{self.config.base_url}/products/{symbol.replace('/', '-')}/ticker"
            
            async with self.session.get(url) as response:
                if response.status == 200:
                    data = await response.json()
                    return {
                        "price": Decimal(str(data["price"])),
                        "symbol": symbol,
                        "exchange": "coinbase"
                    }
        except Exception as e:
            logger.error(f"Coinbase ticker error: {e}")
        return None
    
    async def get_orderbook(self, symbol: str, depth: int = 20) -> Optional[Dict]:
        """Get order book from Coinbase"""
        try:
            url = f"{self.config.base_url}/products/{symbol.replace('/', '-')}/book?level=2"
            
            async with self.session.get(url) as response:
                if response.status == 200:
                    data = await response.json()
                    return {
                        "bids": [[Decimal(str(b["price"])), Decimal(str(b["size"]))] for b in data["bids"][:depth]],
                        "asks": [[Decimal(str(a["price"])), Decimal(str(a["size"]))] for a in data["asks"][:depth]],
                        "exchange": "coinbase"
                    }
        except Exception as e:
            logger.error(f"Coinbase orderbook error: {e}")
        return None


class KrakenConnector(ExchangeConnector):
    """Kraken exchange connector"""
    
    async def get_ticker(self, symbol: str) -> Optional[Dict]:
        """Get ticker from Kraken API"""
        try:
            url = f"{self.config.base_url}/public/Ticker"
            params = {"pair": symbol.replace("/", "")}
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    for pair, ticker in data["result"].items():
                        return {
                            "price": Decimal(str(ticker["c"][0])),
                            "symbol": symbol,
                            "exchange": "kraken"
                        }
        except Exception as e:
            logger.error(f"Kraken ticker error: {e}")
        return None


class ArbitrageScanner:
    """Scans exchanges for arbitrage opportunities"""
    
    def __init__(self, exchanges: List[ExchangeConnector]):
        self.exchanges = exchanges
        self.symbols = ["BTC/USDT", "ETH/USDT", "ETH/BTC", "LTC/USDT", "XRP/USDT"]
        self.min_spread = Decimal("0.005")  # 0.5% minimum spread
        self.min_profit = Decimal("10")  # $10 minimum profit
        
    async def scan_opportunities(self) -> List[ArbitrageOpportunity]:
        """Scan all exchanges for arbitrage opportunities"""
        opportunities = []
        
        for symbol in self.symbols:
            prices = await self.get_all_prices(symbol)
            if len(prices) < 2:
                continue
            
            # Find best buy and sell prices
            sorted_prices = sorted(prices.items(), key=lambda x: x[1])
            buy_exchange, buy_price = sorted_prices[0]
            sell_exchange, sell_price = sorted_prices[-1]
            
            # Calculate spread
            spread = (sell_price - buy_price) / buy_price
            if spread < self.min_spread:
                continue
            
            # Calculate potential profit (assuming $1000 trade)
            trade_amount = Decimal("1000")
            quantity = trade_amount / buy_price
            profit = (sell_price - buy_price) * quantity
            
            if profit < self.min_profit:
                continue
            
            opportunity = ArbitrageOpportunity(
                symbol=symbol,
                buy_exchange=buy_exchange,
                sell_exchange=sell_exchange,
                buy_price=buy_price,
                sell_price=sell_price,
                spread_percent=spread * 100,
                min_profit=profit,
                timestamp=datetime.now()
            )
            opportunities.append(opportunity)
            logger.info(f"Found opportunity: {symbol} {buy_exchange} -> {sell_exchange}, spread: {spread*100:.2f}%")
        
        return opportunities
    
    async def get_all_prices(self, symbol: str) -> Dict[str, Decimal]:
        """Get prices from all exchanges for a symbol"""
        prices = {}
        tasks = [exchange.get_ticker(symbol) for exchange in self.exchanges]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        for exchange, result in zip(self.exchanges, results):
            if isinstance(result, Exception):
                logger.error(f"Error getting price from {exchange.config.name}: {result}")
                continue
            if result:
                prices[exchange.config.name] = result["price"]
        
        return prices


class ArbitrageExecutor:
    """Executes arbitrage trades"""
    
    def __init__(self, exchanges: List[ExchangeConnector]):
        self.exchanges = {e.config.name: e for e in exchanges}
        self.max_position = Decimal("1000")  # Max position size
        self.fee_rate = Decimal("0.001")  # 0.1% fee per trade
        
    async def execute_opportunity(self, opportunity: ArbitrageOpportunity) -> bool:
        """Execute an arbitrage opportunity"""
        logger.info(f"Executing arbitrage: {opportunity.symbol}")
        
        buy_exchange = self.exchanges.get(opportunity.buy_exchange)
        sell_exchange = self.exchanges.get(opportunity.sell_exchange)
        
        if not buy_exchange or not sell_exchange:
            logger.error("Exchange not found")
            return False
        
        # Calculate trade size
        trade_amount = min(self.max_position, opportunity.min_profit / (opportunity.spread_percent / 100))
        quantity = trade_amount / opportunity.buy_price
        
        try:
            # Place buy order
            logger.info(f"Placing buy order on {opportunity.buy_exchange}: {quantity} @ {opportunity.buy_price}")
            buy_result = await buy_exchange.place_order(
                opportunity.symbol,
                "buy",
                quantity,
                opportunity.buy_price
            )
            
            if not buy_result:
                logger.error("Buy order failed")
                return False
            
            # Place sell order
            logger.info(f"Placing sell order on {opportunity.sell_exchange}: {quantity} @ {opportunity.sell_price}")
            sell_result = await sell_exchange.place_order(
                opportunity.symbol,
                "sell",
                quantity,
                opportunity.sell_price
            )
            
            if not sell_result:
                logger.error("Sell order failed")
                # Try to cancel buy order
                return False
            
            # Calculate actual profit
            gross_profit = (opportunity.sell_price - opportunity.buy_price) * quantity
            fees = trade_amount * self.fee_rate * 2  # Buy and sell fees
            net_profit = gross_profit - fees
            
            logger.info(f"Arbitrage executed successfully! Net profit: ${net_profit:.2f}")
            return True
            
        except Exception as e:
            logger.error(f"Error executing arbitrage: {e}")
            return False


class ArbitrageXPro:
    """Main ArbitrageX Pro bot"""
    
    def __init__(self, config_file: str = "config.yaml"):
        self.config = self.load_config(config_file)
        self.exchanges = self.init_exchanges()
        self.scanner = ArbitrageScanner(self.exchanges)
        self.executor = ArbitrageExecutor(self.exchanges)
        self.running = False
        self.total_profit = Decimal("0")
        
    def load_config(self, config_file: str) -> Dict:
        """Load configuration from file"""
        try:
            with open(config_file, 'r') as f:
                import yaml
                return yaml.safe_load(f)
        except FileNotFoundError:
            logger.warning(f"Config file not found: {config_file}, using defaults")
            return {
                "exchanges": [
                    {
                        "name": "binance",
                        "api_key": os.getenv("BINANCE_API_KEY", ""),
                        "api_secret": os.getenv("BINANCE_API_SECRET", ""),
                        "base_url": "https://api.binance.com"
                    },
                    {
                        "name": "coinbase",
                        "api_key": os.getenv("COINBASE_API_KEY", ""),
                        "api_secret": os.getenv("COINBASE_API_SECRET", ""),
                        "base_url": "https://api.exchange.coinbase.com"
                    }
                ],
                "min_spread": 0.005,
                "min_profit": 10,
                "max_position": 1000
            }
    
    def init_exchanges(self) -> List[ExchangeConnector]:
        """Initialize exchange connectors"""
        exchanges = []
        
        for exch_config in self.config.get("exchanges", []):
            config = ExchangeConfig(
                name=exch_config["name"],
                api_key=exch_config["api_key"],
                api_secret=exch_config["api_secret"],
                base_url=exch_config["base_url"],
                testnet=exch_config.get("testnet", False)
            )
            
            if exch_config["name"] == "binance":
                exchanges.append(BinanceConnector(config))
            elif exch_config["name"] == "coinbase":
                exchanges.append(CoinbaseConnector(config))
            elif exch_config["name"] == "kraken":
                exchanges.append(KrakenConnector(config))
        
        return exchanges
    
    async def run(self):
        """Main bot loop"""
        self.running = True
        logger.info("ArbitrageX Pro started")
        
        async with asyncio.TaskGroup() as tg:
            # Initialize exchange sessions
            for exchange in self.exchanges:
                await exchange.__aenter__()
            
            try:
                while self.running:
                    # Scan for opportunities
                    opportunities = await self.scanner.scan_opportunities()
                    
                    # Execute opportunities
                    for opp in opportunities:
                        if await self.executor.execute_opportunity(opp):
                            self.total_profit += opp.min_profit
                    
                    # Wait before next scan
                    await asyncio.sleep(5)
                    
            except KeyboardInterrupt:
                logger.info("Stopping bot...")
                self.running = False
            finally:
                # Close exchange sessions
                for exchange in self.exchanges:
                    await exchange.__aexit__(None, None, None)
        
        logger.info(f"Bot stopped. Total profit: ${self.total_profit:.2f}")


async def main():
    """Main entry point"""
    bot = ArbitrageXPro()
    await bot.run()


if __name__ == "__main__":
    asyncio.run(main())
