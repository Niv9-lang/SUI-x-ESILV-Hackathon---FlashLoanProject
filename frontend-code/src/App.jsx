import "./App.css";
import { ConnectButton, useCurrentAccount } from "@mysten/dapp-kit";
import fond3 from "./assets/fond3.jpg";

function App() {
  //=null si aucun wallet n'est connecté et contient un objet {adress: "0x123..."}
  // qunad Phantom est connecté
  const currentAccount = useCurrentAccount();

  // petite fonction utilitaire pour afficher une adresse raccourcie
  const shortAddress = (address) =>
    address ? `${address.slice(0, 6)}...${address.slice(-4)}` : "";

  return (
    <div className="app">
      <aside className="sidebar">
        <div className="sidebar-logo">
          <span className="logo-dot" />
          <span className="logo-text">SUI-CS</span>
        </div>

        <nav className="sidebar-nav">
          <button className="nav-item nav-item-active">Dashboard</button>
          <button className="nav-item">Pools</button>
          <button className="nav-item">Bots</button>
          <button className="nav-item">Portfolio</button>
        </nav>

        <div className="sidebar-footer">
          <p className="sidebar-network">SUI Devnet</p>
        </div>
      </aside>

      <main className="main">
        <header className="topbar">
          <div>
            <h1 className="topbar-title">Flash Loan Dashboard</h1>
            <p className="topbar-subtitle">
              Monitor liquidity, launch arbitrage bots and manage your positions.
            </p>
          </div>

          {/* Zone wallet à droite */}
          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            {currentAccount && (
              <div className="wallet-chip">
                <span className="wallet-dot" />
                <span className="wallet-address">
                  {shortAddress(currentAccount.address)}
                </span>
              </div>
            )}

            {/* Bouton de connexion SUI dapp-kit */}
            <ConnectButton />
          </div>
        </header>

        <section className="stats-grid">
          <div className="card">
            <p className="card-label">Total Liquidity</p>
            <p className="card-value">$12.4M</p>
            <p className="card-sub">Across all SUI pools</p>
          </div>
          <div className="card">
            <p className="card-label">Active Bots</p>
            <p className="card-value">27</p>
            <p className="card-sub">Running arbitrage strategies</p>
          </div>
          <div className="card">
            <p className="card-label">Protocol Revenue (24h)</p>
            <p className="card-value">$8 520</p>
            <p className="card-sub">From flash loan fees</p>
          </div>
        </section>

        <section className="content-grid">
          <div className="card card-large">
            <div className="card-header">
              <h2>Flash Loan Pools</h2>
              <span className="badge">SUI / USDC / ETH</span>
            </div>

            <table className="table">
              <thead>
                <tr>
                  <th>Pool</th>
                  <th>Liquidity</th>
                  <th>Fee</th>
                  <th>Oracle</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>SUI / USDC</td>
                  <td>$4.1M</td>
                  <td>0.09%</td>
                  <td>Pyth</td>
                  <td>
                    <button className="table-btn">Arbitrage</button>
                  </td>
                </tr>
                <tr>
                  <td>ETH / USDC</td>
                  <td>$3.6M</td>
                  <td>0.12%</td>
                  <td>Pyth</td>
                  <td>
                    <button className="table-btn">Arbitrage</button>
                  </td>
                </tr>
                <tr>
                  <td>BTC / USDC</td>
                  <td>$2.7M</td>
                  <td>0.10%</td>
                  <td>Pyth</td>
                  <td>
                    <button className="table-btn">Arbitrage</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div className="card">
            <div className="card-header">
              <h2>Quick Flash Loan</h2>
            </div>

            <div className="form-group">
              <label>Asset</label>
              <select>
                <option>SUI</option>
                <option>USDC</option>
                <option>ETH</option>
              </select>
            </div>

            <div className="form-group">
              <label>Amount</label>
              <input type="number" placeholder="0.00" />
            </div>

            <div className="form-group">
              <label>Strategy</label>
              <select>
                <option>Best arbitrage on Cetus / Scallop</option>
                <option>Simple SUI &lt;&gt; USDC spread</option>
                <option>Custom bot (coming soon)</option>
              </select>
            </div>

            <button className="primary-btn">Simulate Flash Loan</button>

            <p className="hint">
              All operations happen in a single SUI transaction. If the loan is
              not fully repaid, the transaction is reverted.
            </p>
          </div>
        </section>
      </main>
    </div>
  );
}

export default App;
