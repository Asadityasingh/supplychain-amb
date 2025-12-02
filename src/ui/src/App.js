import { useState, useEffect } from 'react';
import Dashboard from './components/Dashboard';
import CreateAssetForm from './components/CreateAssetForm';
import TransferAssetForm from './components/TransferAssetForm';
import MonitoringPanel from './components/MonitoringPanel';
import './App.css';

function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [assets, setAssets] = useState([]);
  const [assetOrigins, setAssetOrigins] = useState({});
  const [assetTransactions, setAssetTransactions] = useState({});
  const [error, setError] = useState(null);
  const [fabricStatus, setFabricStatus] = useState('unknown');
  const [blockchainInfo, setBlockchainInfo] = useState(null);

  useEffect(() => {
    fetchAssets();
    checkBlockchainStatus();
    const interval = setInterval(() => {
      fetchAssets();
      checkBlockchainStatus();
    }, 10000);
    return () => clearInterval(interval);
  }, []);

  const checkBlockchainStatus = async () => {
    try {
      const response = await fetch(`${process.env.REACT_APP_API_ENDPOINT || 'http://localhost:3001'}/health`);
      if (!response.ok) throw new Error('Failed to check status');
      const data = await response.json();
      if (data.blockchain) {
        setBlockchainInfo(data.blockchain);
        if (data.blockchain.connected) {
          setFabricStatus('connected');
        } else if (data.blockchain.error && data.blockchain.error.includes('certificate')) {
          setFabricStatus('needs-certs');
        } else {
          setFabricStatus('configured');
        }
      }
    } catch (err) {
      console.error('Status check error:', err);
    }
  };

  const fetchAssets = async () => {
    try {
      const response = await fetch(`${process.env.REACT_APP_API_ENDPOINT || 'http://localhost:3001'}/assets`);
      if (!response.ok) throw new Error('Failed to fetch assets');
      const data = await response.json();
      const fetchedAssets = data.data || [];
      
      // Track origins: store the first owner we see for each asset
      setAssetOrigins(prev => {
        const newOrigins = { ...prev };
        fetchedAssets.forEach(asset => {
          if (!newOrigins[asset.ID]) {
            newOrigins[asset.ID] = asset.owner || asset.Owner;
          }
        });
        return newOrigins;
      });
      
      // Merge transaction IDs from cache
      const assetsWithTxIds = fetchedAssets.map(asset => ({
        ...asset,
        transactionId: assetTransactions[asset.ID] || asset.transactionId
      }));
      
      setAssets(assetsWithTxIds);
      setError(null);
      setFabricStatus(data.source === 'blockchain' ? 'connected' : 'mock');
    } catch (err) {
      setError(err.message);
      setFabricStatus('error');
    }
  };

  const handleAssetCreated = async () => {
    setActiveTab('dashboard');
    await fetchAssets();
  };

  const handleAssetTransferred = async () => {
    setActiveTab('dashboard');
    await fetchAssets();
  };

  return (
    <div className="app-container">
      <nav className="navbar navbar-dark bg-dark shadow-sm sticky-top">
        <div className="container-fluid">
          <span className="navbar-brand mb-0 h1">
            <span className="me-2">🏭</span>
            Supply Chain Tracker
          </span>
          <div className="d-flex gap-2">
            <button
              className={`btn ${activeTab === 'dashboard' ? 'btn-light' : 'btn-outline-light'}`}
              onClick={() => setActiveTab('dashboard')}
            >
              📊 Dashboard
            </button>
            <button
              className={`btn ${activeTab === 'create' ? 'btn-light' : 'btn-outline-light'}`}
              onClick={() => setActiveTab('create')}
            >
              ➕ Create
            </button>
            <button
              className={`btn ${activeTab === 'transfer' ? 'btn-light' : 'btn-outline-light'}`}
              onClick={() => setActiveTab('transfer')}
            >
              🔄 Transfer
            </button>
            <button
              className={`btn ${activeTab === 'monitor' ? 'btn-light' : 'btn-outline-light'}`}
              onClick={() => setActiveTab('monitor')}
            >
              📡 Monitor
            </button>
          </div>
          <div className="ms-auto d-flex gap-2 align-items-center">
            <span className={`badge ${
              fabricStatus === 'connected' ? 'bg-success' : 
              fabricStatus === 'configured' ? 'bg-info' :
              fabricStatus === 'needs-certs' ? 'bg-warning' :
              fabricStatus === 'mock' ? 'bg-secondary' : 
              'bg-danger'
            }`} title={blockchainInfo ? `Network: ${blockchainInfo.network}` : ''}>
              {fabricStatus === 'connected' && '🔗 Live Blockchain'}
              {fabricStatus === 'configured' && '⚙️ Blockchain Ready'}
              {fabricStatus === 'needs-certs' && '🔐 Needs Certificates'}
              {fabricStatus === 'mock' && '📦 Mock Data'}
              {fabricStatus === 'error' && '❌ Error'}
              {fabricStatus === 'unknown' && '❓ Checking...'}
            </span>
            {blockchainInfo && (
              <div className="small text-muted ms-2" style={{ maxWidth: '300px', lineHeight: '1.2' }}>
                <div>🏭 {blockchainInfo.member ? 'AMB: Org1' : ''}</div>
                {blockchainInfo.error && <div className="text-danger small">⚠️ {blockchainInfo.error}</div>}
              </div>
            )}
          </div>
        </div>
      </nav>

      <main className="container-fluid py-4">
        {error && (
          <div className="alert alert-danger alert-dismissible fade show" role="alert">
            <strong>⚠️ Error:</strong> {error}
            <button type="button" className="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
          </div>
        )}

        {activeTab === 'dashboard' && (
          <Dashboard assets={assets} onRefresh={fetchAssets} />
        )}
        {activeTab === 'create' && (
          <CreateAssetForm onSuccess={handleAssetCreated} onTransactionId={(assetId, txId) => {
            setAssetTransactions(prev => ({ ...prev, [assetId]: txId }));
          }} />
        )}
        {activeTab === 'transfer' && (
          <TransferAssetForm assets={assets} onSuccess={handleAssetTransferred} onTransactionId={(assetId, txId) => {
            setAssetTransactions(prev => ({ ...prev, [assetId]: txId }));
          }} />
        )}
        {activeTab === 'monitor' && (
          <MonitoringPanel assets={assets} assetOrigins={assetOrigins} />
        )}
      </main>
    </div>
  );
}

export default App;
