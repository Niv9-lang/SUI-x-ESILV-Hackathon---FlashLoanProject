import { useState } from "react";
import "./App.css";
import { ConnectButton, useCurrentAccount } from "@mysten/dapp-kit";
import logoSIT from "./assets/logoSUI.jpg";
import logoDEEP from "./assets/logoDEEP.jpg";
import logoSITE from "./assets/logoSITE.jpg";
import cocotier from "./assets/cocotier.jpg";


function App() {
  // = null si aucun wallet n'est connecté, sinon { address: "0x123..." }
  const currentAccount = useCurrentAccount();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedPool, setSelectedPool] = useState(null);

  const openFlashLoanModal = (poolName) => {
    setSelectedPool(poolName);
    setIsModalOpen(true);
  };

  const closeFlashLoanModal = () => {
    setIsModalOpen(false);
  };


  // Affiche une adresse raccourcie
  const shortAddress = (address) =>
    address ? `${address.slice(0, 6)}...${address.slice(-4)}` : "";

  return (
  <div className="app">
    {/* 🔹 TOUT le reste du site (bande + main) est DANS .content */}
    <div className="top-banner" />

    <main className="main">
      <header className="topbar">
        <div className="topbar-left">
          <img src={logoSITE} alt="SUI-CS logo" className="logo-img" />
          <span className="logo-text">SUI-CS</span>
        </div>
        <div className="topbar-center">
          <h1 className="topbar-title">Make free money with Flash Loan</h1>
          <p className="topbar-subtitle">
            Monitor liquidity, launch arbitrage bots and manage your positions.
          </p>
        </div>
{/*style={{ display: "flex", alignItems: "center", gap: "12px" }}*/}
        <div className="topbar-right">
          {currentAccount && (
            <div className="wallet-chip">
              <span className="wallet-dot"></span>
              <span className="wallet-address">{currentAccount ? "Connected" : ""}
              </span>
            </div>
          )}
          <ConnectButton />
        </div>
      </header>

        <section className="stats-grid">
          <div className="card">
            <p className="card-label">Active Bots</p>
            <p className="card-value">27</p>
            <p className="card-sub">Running arbitrage strategies</p>
          </div>
          <div className="card">
            <p className="card-label">Protocol Revenue (24h)</p>
            <p className="card-value">$8 520</p>
            <p className="card-sub">From flash loan</p>
          </div>
        </section>

        <section className="content-grid">
          <div className="card card-large">
            <div className="card-header">
              <h2>Flash Loan Pools</h2>
              <span className="badge">SUI / DEEP</span>
            </div>
            {/* Cadre cocotier */}
            <div className="card-palm-top-right">
              <img src={cocotier} alt="Palm" className="card-palm-tree" />
            </div>

            <table className="table">
              <thead>
                <tr>
                  <th>Pool</th>
                  <th>Liquidity</th>
                  <th>Fee</th>
                  <th>Flash Loan</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td className="pool-cell">
                    <span>SUI / DEEP</span>
                  </td>
                  <td>$4.1M</td>
                  <td>0.09%</td>
                  <td>
                    <button 
                      className="table-btn"
                      onClick={() => openFlashLoanModal("SUI / USDC")}
                    >
                      Flash
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
        {isModalOpen && (
          <div className="modal-overlay" onClick={closeFlashLoanModal}>
            <div
              className="modal"
              onClick={(e) => e.stopPropagation()} // empêche la fermeture si on clique dans la popup
            >
              <div className="modal-header">
                <h2>Quick Flash Loan</h2>
                <button className="modal-close" onClick={closeFlashLoanModal}>
          ✕
                </button>
              </div>

              <p className="modal-subtitle">Pool: {selectedPool}</p>

              <div className="form-group">
                <label>Amount</label>
                <input type="number" placeholder="0.00" />
              </div>

              <div className="form-group">
                <label>Strategy</label>
                <select>
                  <option>Best arbitrage on Cetus / Scallop</option>
                  <option>Simple spread on SUI</option>
                  <option>Custom bot (coming soon)</option>
                </select>
              </div>

              <button className="primary-btn">Simulate Flash Loan</button>

              <p className="hint">
                This is a flash loan simulation on {selectedPool}. All operations happen
                in a single SUI transaction.
              </p>
            </div>
          </div>
        )}
      </main>
    </div>
);

}

export default App;