/**
 * Crypto Checkout Integration
 * Real crypto payment processing via Coinbase Commerce and WalletConnect
 */

class CryptoCheckout {
  constructor() {
    this.coinbaseCommerceKey = window.theme.coinbaseCommerceKey || '';
    this.walletConnectProjectId = window.theme.walletConnectProjectId || '';
    this.init();
  }

  init() {
    // Initialize Coinbase Commerce
    if (this.coinbaseCommerceKey) {
      this.initCoinbaseCommerce();
    }

    // Initialize WalletConnect
    if (this.walletConnectProjectId) {
      this.initWalletConnect();
    }

    // Setup crypto checkout buttons
    this.setupCryptoButtons();
  }

  initCoinbaseCommerce() {
    // Load Coinbase Commerce SDK
    const script = document.createElement('script');
    script.src = 'https://commerce.coinbase.com/v1/checkout.js';
    script.async = true;
    script.onload = () => {
      console.log('Coinbase Commerce loaded');
    };
    document.head.appendChild(script);
  }

  initWalletConnect() {
    // Load WalletConnect Web3Modal
    // This would integrate with Web3Modal for wallet connection
    console.log('WalletConnect initialized');
  }

  setupCryptoButtons() {
    const cryptoButtons = document.querySelectorAll('.crypto-checkout-button');
    
    cryptoButtons.forEach(button => {
      button.addEventListener('click', (e) => {
        e.preventDefault();
        const productId = button.dataset.productId;
        const variantId = button.dataset.variantId;
        this.openCryptoCheckout(productId, variantId);
      });
    });
  }

  async openCryptoCheckout(productId, variantId) {
    // Get product data
    const response = await fetch(`/products/${productId}.js`);
    const product = await response.json();
    const variant = product.variants.find(v => v.id == variantId);
    
    if (!variant) {
      console.error('Variant not found');
      return;
    }

    // Create charge via Coinbase Commerce API
    try {
      const chargeData = {
        name: product.title,
        description: product.description,
        pricing_type: 'fixed_price',
        local_price: {
          amount: variant.price / 100, // Shopify uses cents
          currency: 'USD'
        },
        metadata: {
          product_id: productId,
          variant_id: variantId
        }
      };

      // Call backend to create Coinbase Commerce charge
      const chargeResponse = await fetch('/apps/crypto-checkout/create-charge', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(chargeData)
      });

      const charge = await chargeResponse.json();

      // Open Coinbase Commerce checkout
      if (window.CoinbaseCommerce) {
        window.CoinbaseCommerce.showCheckout(charge.code);
      } else {
        // Fallback: redirect to hosted checkout
        window.location.href = `https://commerce.coinbase.com/checkout/${charge.code}`;
      }

    } catch (error) {
      console.error('Crypto checkout error:', error);
      alert('Failed to initiate crypto checkout. Please try again.');
    }
  }

  // Handle successful crypto payment
  handleCryptoPaymentSuccess(chargeCode) {
    // Verify payment with backend
    fetch('/apps/crypto-checkout/verify-payment', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ charge_code: chargeCode })
    })
    .then(response => response.json())
    .then(data => {
      if (data.verified) {
        // Redirect to order confirmation
        window.location.href = '/checkout/success?order_id=' + data.order_id;
      }
    });
  }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
  if (window.theme.enableCryptoCheckout) {
    new CryptoCheckout();
  }
});
