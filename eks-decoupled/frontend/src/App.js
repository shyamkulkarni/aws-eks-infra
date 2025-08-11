import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080';
const ASSETS_URL = process.env.REACT_APP_ASSETS_URL || '';

function App() {
  const [products, setProducts] = useState([]);
  const [cart, setCart] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      const response = await axios.get(`${API_URL}/catalog/products`);
      setProducts(response.data);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching products:', error);
      setLoading(false);
    }
  };

  const addToCart = async (product) => {
    try {
      await axios.post(`${API_URL}/carts/customer123/items`, {
        productId: product.id,
        quantity: 1
      });
      setCart([...cart, product]);
    } catch (error) {
      console.error('Error adding to cart:', error);
    }
  };

  if (loading) {
    return <div className="loading">Loading products...</div>;
  }

  return (
    <div className="App">
      <header className="App-header">
        <h1>🛍️ Retail Store</h1>
        <p>Decoupled Architecture: Amplify Frontend + EKS Backend</p>
        <div className="cart-info">Cart: {cart.length} items</div>
      </header>

      <main className="products-grid">
        {products.length > 0 ? (
          products.map((product) => (
            <div key={product.id} className="product-card">
              <img src={product.imageUrl ? `${ASSETS_URL}${product.imageUrl}` : `${ASSETS_URL}/images/placeholder.jpg`} alt={product.name} />
              <h3>{product.name}</h3>
              <p className="price">${product.price}</p>
              <button onClick={() => addToCart(product)}>Add to Cart</button>
            </div>
          ))
        ) : (
          <div className="no-products">
            <h2>No products available</h2>
            <p>Backend API: {API_URL}</p>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;