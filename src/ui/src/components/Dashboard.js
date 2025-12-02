import { useState } from 'react';

export default function Dashboard({ assets, onRefresh }) {
  const [searchTerm, setSearchTerm] = useState('');
  const [filterOwner, setFilterOwner] = useState('');
  const [loading, setLoading] = useState(false);

  const filteredAssets = assets.filter(asset => {
    const matchesSearch = asset.ID?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (asset.name || asset.Name)?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (asset.location || asset.Location)?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesOwner = !filterOwner || (asset.owner || asset.Owner) === filterOwner;
    return matchesSearch && matchesOwner;
  });

  const uniqueOwners = [...new Set(assets.map(a => a.owner || a.Owner).filter(Boolean))];

  const handleRefresh = async () => {
    setLoading(true);
    await onRefresh();
    setLoading(false);
  };

  return (
    <div>
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h2 className="h2 mb-0">📊 Asset Dashboard</h2>
        <button
          onClick={handleRefresh}
          disabled={loading}
          className="btn btn-primary"
        >
          <span>{loading ? '⏳ Refreshing...' : '🔄 Refresh'}</span>
        </button>
      </div>

      <div className="row g-3 mb-4">
        <div className="col-md-4">
          <div className="card text-center">
            <div className="card-body">
              <h5 className="card-title text-muted">Total Assets</h5>
              <h2 className="text-primary">{assets.length}</h2>
            </div>
          </div>
        </div>
        <div className="col-md-4">
          <div className="card text-center">
            <div className="card-body">
              <h5 className="card-title text-muted">Unique Owners</h5>
              <h2 className="text-success">{uniqueOwners.length}</h2>
            </div>
          </div>
        </div>
        <div className="col-md-4">
          <div className="card text-center">
            <div className="card-body">
              <h5 className="card-title text-muted">Locations</h5>
              <h2 className="text-info">{new Set(assets.map(a => a.Location)).size}</h2>
            </div>
          </div>
        </div>
      </div>

      <div className="card shadow-sm">
        <div className="card-body">
          <div className="row g-3 mb-4">
            <div className="col-md-6">
              <input
                type="text"
                placeholder="🔍 Search by ID, name, or location..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="form-control"
              />
            </div>
            <div className="col-md-6">
              <select
                value={filterOwner}
                onChange={(e) => setFilterOwner(e.target.value)}
                className="form-select"
              >
                <option value="">All Owners</option>
                {uniqueOwners.map(owner => (
                  <option key={owner} value={owner}>{owner}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="table-responsive">
            <table className="table table-hover">
              <thead className="table-dark">
                <tr>
                  <th>Asset ID</th>
                  <th>Name</th>
                  <th>Current Location</th>
                  <th>Owner</th>
                  <th>Last Updated</th>
                  <th>Transaction ID</th>
                </tr>
              </thead>
              <tbody>
                {filteredAssets.length > 0 ? (
                  filteredAssets.map(asset => (
                    <tr key={asset.ID}>
                      <td><code>{asset.ID}</code></td>
                      <td><strong>{asset.name || asset.Name || 'N/A'}</strong></td>
                      <td>
                        <span className="badge bg-info">{asset.location || asset.Location || 'N/A'}</span>
                      </td>
                      <td>
                        <span className="badge bg-success">{asset.owner || asset.Owner || 'N/A'}</span>
                      </td>
                      <td>
                        {asset.timestamp || asset.Timestamp ? new Date(parseInt(asset.timestamp || asset.Timestamp) * 1000 || asset.timestamp || asset.Timestamp).toLocaleDateString() : 'N/A'}
                      </td>
                      <td>
                        {asset.transactionId ? (
                          <small className="text-muted" style={{fontSize: '0.75rem'}} title={asset.transactionId}>
                            {asset.transactionId.substring(0, 8)}...{asset.transactionId.substring(asset.transactionId.length - 6)}
                          </small>
                        ) : (
                          <small className="text-muted">-</small>
                        )}
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="6" className="text-center text-muted py-5">
                      No assets found
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {filteredAssets.length > 0 && (
            <div className="text-muted small mt-3">
              Showing {filteredAssets.length} of {assets.length} assets
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
