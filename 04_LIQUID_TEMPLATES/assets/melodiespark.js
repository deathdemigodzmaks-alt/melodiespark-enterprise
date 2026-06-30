/**
 * MelodieSpark Theme JavaScript
 * Real e-commerce functionality
 */

window.MelodieSpark = (function() {
  'use strict';

  const config = {
    stripePublicKey: window.theme.stripePublicKey || '',
    enableStripe: window.theme.enableStripeElements || false,
    enableCrypto: window.theme.enableCryptoCheckout || false,
    enableKarma: window.theme.enableKarmaWidget || false
  };

  // Initialize Stripe
  let stripe = null;
  let cardElement = null;

  function initStripe() {
    if (!config.enableStripe || !config.stripePublicKey) return;

    stripe = Stripe(config.stripePublicKey);
    
    // Create Stripe Elements when modal opens
    const stripeModal = document.getElementById('stripe-payment-modal');
    const buyNowButtons = document.querySelectorAll('.buy-now-button.stripe-checkout');
    
    buyNowButtons.forEach(button => {
      button.addEventListener('click', async function() {
        const productId = this.dataset.productId;
        const variantId = this.dataset.variantId;
        
        // Show modal
        stripeModal.classList.remove('hidden');
        
        // Create card element if not exists
        if (!cardElement) {
          const elements = stripe.elements();
          cardElement = elements.create('card');
          cardElement.mount('#stripe-card-element');
        }
        
        // Handle form submission
        const submitButton = document.getElementById('stripe-submit-button');
        submitButton.onclick = async function() {
          submitButton.disabled = true;
          submitButton.textContent = 'Processing...';
          
          try {
            // Create payment intent via Shopify
            const response = await fetch('/apps/stripe/create-payment-intent', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                product_id: productId,
                variant_id: variantId
              })
            });
            
            const { clientSecret } = await response.json();
            
            // Confirm payment
            const { error, paymentIntent } = await stripe.confirmCardPayment(clientSecret, {
              payment_method: {
                card: cardElement,
                billing_details: {
                  name: 'Customer'
                }
              }
            });
            
            if (error) {
              document.getElementById('payment-error').textContent = error.message;
              submitButton.disabled = false;
              submitButton.textContent = 'Pay';
            } else {
              // Payment successful
              window.location.href = '/checkout/success?payment_intent=' + paymentIntent.id;
            }
          } catch (err) {
            document.getElementById('payment-error').textContent = 'Payment failed. Please try again.';
            submitButton.disabled = false;
            submitButton.textContent = 'Pay';
          }
        };
      });
    });
    
    // Close modal
    document.querySelector('.close-modal').addEventListener('click', function() {
      stripeModal.classList.add('hidden');
    });
  }

  // Crypto price updates
  function initCryptoPrices() {
    if (!config.enableCrypto) return;

    async function updateCryptoPrices() {
      try {
        // Fetch prices from CoinGecko API (free, no API key needed)
        const response = await fetch('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd');
        const prices = await response.json();
        
        const btcPrice = prices.bitcoin.usd;
        const ethPrice = prices.ethereum.usd;
        
        // Update product page crypto prices
        document.querySelectorAll('.crypto-price').forEach(el => {
          const fiatPrice = parseFloat(el.dataset.fiatPrice);
          if (fiatPrice && btcPrice) {
            const btcValue = (fiatPrice / btcPrice).toFixed(6);
            el.querySelector('.btc-price').textContent = `₿${btcValue}`;
          }
          if (fiatPrice && ethPrice) {
            const ethValue = (fiatPrice / ethPrice).toFixed(6);
            el.querySelector('.eth-price').textContent = `Ξ${ethValue}`;
          }
        });
        
        // Update header ticker
        const btcTicker = document.getElementById('btc-price');
        const ethTicker = document.getElementById('eth-price');
        if (btcTicker) btcTicker.textContent = `$${btcPrice.toLocaleString()}`;
        if (ethTicker) ethTicker.textContent = `$${ethPrice.toLocaleString()}`;
        
      } catch (error) {
        console.error('Failed to fetch crypto prices:', error);
      }
    }

    updateCryptoPrices();
    setInterval(updateCryptoPrices, 60000); // Update every minute
  }

  // Variant selector
  function initVariantSelector() {
    const variantSelect = document.getElementById('variant-select');
    if (!variantSelect) return;

    variantSelect.addEventListener('change', function() {
      const selectedOption = this.options[this.selectedIndex];
      const price = selectedOption.dataset.price;
      const comparePrice = selectedOption.dataset.comparePrice;
      
      // Update price display
      const priceEl = document.querySelector('.product-price .price');
      const comparePriceEl = document.querySelector('.product-price .compare-price');
      
      if (priceEl) {
        priceEl.textContent = '$' + (parseFloat(price) / 100).toFixed(2);
      }
      
      if (comparePriceEl && comparePrice && parseFloat(comparePrice) > 0) {
        comparePriceEl.textContent = '$' + (parseFloat(comparePrice) / 100).toFixed(2);
        comparePriceEl.style.display = 'inline';
      } else if (comparePriceEl) {
        comparePriceEl.style.display = 'none';
      }
      
      // Update buy buttons
      const buyButtons = document.querySelectorAll('.buy-now-button, .crypto-checkout-button');
      buyButtons.forEach(btn => {
        btn.dataset.variantId = selectedOption.value;
        btn.disabled = selectedOption.disabled;
      });
    });
  }

  // Cart drawer
  function initCartDrawer() {
    const cartLinks = document.querySelectorAll('.cart-link');
    // Cart drawer implementation would go here
  }

  // Mobile menu
  function initMobileMenu() {
    const menuToggle = document.querySelector('.mobile-menu-toggle');
    const navMenu = document.querySelector('.nav-menu');
    
    if (!menuToggle || !navMenu) return;

    menuToggle.addEventListener('click', function() {
      navMenu.classList.toggle('mobile-active');
    });
  }

  // Initialize all components
  function init() {
    initStripe();
    initCryptoPrices();
    initVariantSelector();
    initCartDrawer();
    initMobileMenu();
  }

  // Public API
  return {
    init: init,
    config: config
  };

})();

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', function() {
  window.MelodieSpark.init();
});
