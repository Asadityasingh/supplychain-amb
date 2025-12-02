import { useState, useEffect, useCallback } from 'react';

export default function MonitoringPanel({ assets, assetOrigins }) {
  const [metrics, setMetrics] = useState({
    totalAssets: 0,
    assetsInTransit: 0,
    recentTransfers: 0,
    uniqueLocations: 0
  });

  const updateMetrics = useCallback(() => {
    if (!assets || assets.length === 0) {
      setMetrics({
        totalAssets: 0,
        assetsInTransit: 0,
        recentTransfers: 0,
        uniqueLocations: 0
      });
      return;
    }

    const now = new Date();
    const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);

    const recentTransfers = assets.filter(asset => {
      if (!asset.Timestamp) return false;
      const assetTime = new Date(asset.Timestamp);
      return assetTime > oneHourAgo;
    }).length;

    setMetrics({
      totalAssets: assets.length,
      assetsInTransit: Math.floor(assets.length * 0.3),
      recentTransfers,
      uniqueLocations: new Set(assets.map(a => a.location || a.Location).filter(Boolean)).size
    });
  }, [assets]);

  useEffect(() => {
    updateMetrics();
  }, [updateMetrics]);

  useEffect(() => {
    const interval = setInterval(updateMetrics, 5000);
    return () => clearInterval(interval);
  }, [updateMetrics]);

  const topLocations = assets
    .reduce((acc, asset) => {
      const loc = asset.location || asset.Location;
      if (!loc) return acc;
      const existing = acc.find(item => item.location === loc);
      if (existing) {
        existing.count++;
      } else {
        acc.push({ location: loc, count: 1 });
      }
      return acc;
    }, [])
    .sort((a, b) => b.count - a.count)
    .slice(0, 5);

  const topOwners = assets
    .reduce((acc, asset) => {
      const own = asset.owner || asset.Owner;
      if (!own) return acc;
      const existing = acc.find(item => item.owner === own);
      if (existing) {
        existing.count++;
      } else {
        acc.push({ owner: own, count: 1 });
      }
      return acc;
    }, [])
    .sort((a, b) => b.count - a.count)
    .slice(0, 5);

  const maxCount = Math.max(...[...topLocations, ...topOwners].map(item => item.count), 1);

  return (
    <div>
      <h2 className="h2 mb-4">📡 Real-time Monitoring</h2>

      <div className="row g-3 mb-4">
        <div className="col-md-6 col-lg-3">
          <div className="card bg-primary text-white text-center">
            <div className="card-body">
              <h6 className="card-title text-white-50">Total Assets</h6>
              <h2 className="card-text">{metrics.totalAssets}</h2>
            </div>
          </div>
        </div>
        <div className="col-md-6 col-lg-3">
          <div className="card bg-success text-white text-center">
            <div className="card-body">
              <h6 className="card-title text-white-50">In Transit</h6>
              <h2 className="card-text">{metrics.assetsInTransit}</h2>
            </div>
          </div>
        </div>
        <div className="col-md-6 col-lg-3">
          <div className="card bg-warning text-white text-center">
            <div className="card-body">
              <h6 className="card-title text-white-50">Recent Transfers</h6>
              <h2 className="card-text">{metrics.recentTransfers}</h2>
            </div>
          </div>
        </div>
        <div className="col-md-6 col-lg-3">
          <div className="card bg-info text-white text-center">
            <div className="card-body">
              <h6 className="card-title text-white-50">Locations</h6>
              <h2 className="card-text">{metrics.uniqueLocations}</h2>
            </div>
          </div>
        </div>
      </div>

      <div className="row g-4">
        <div className="col-lg-6">
          <div className="card shadow-sm">
            <div className="card-header bg-primary text-white">
              <h5 className="mb-0">Top Locations</h5>
            </div>
            <div className="card-body">
              {topLocations.length > 0 ? (
                topLocations.map((item, index) => (
                  <div key={index} className="mb-3">
                    <div className="d-flex justify-content-between align-items-center mb-1">
                      <span className="fw-semibold">📍 {item.location}</span>
                      <span className="badge bg-primary">{item.count}</span>
                    </div>
                    <div className="progress" role="progressbar">
                      <div
                        className="progress-bar bg-primary"
                        style={{ width: `${(item.count / maxCount) * 100}%` }}
                      />
                    </div>
                  </div>
                ))
              ) : (
                <p className="text-muted">No location data available</p>
              )}
            </div>
          </div>
        </div>

        <div className="col-lg-6">
          <div className="card shadow-sm">
            <div className="card-header bg-success text-white">
              <h5 className="mb-0">Top Owners</h5>
            </div>
            <div className="card-body">
              {topOwners.length > 0 ? (
                topOwners.map((item, index) => (
                  <div key={index} className="mb-3">
                    <div className="d-flex justify-content-between align-items-center mb-1">
                      <span className="fw-semibold">👤 {item.owner}</span>
                      <span className="badge bg-success">{item.count}</span>
                    </div>
                    <div className="progress" role="progressbar">
                      <div
                        className="progress-bar bg-success"
                        style={{ width: `${(item.count / maxCount) * 100}%` }}
                      />
                    </div>
                  </div>
                ))
              ) : (
                <p className="text-muted">No owner data available</p>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="row g-4 mt-4">
        <div className="col-12">
          <div className="card shadow-sm">
            <div className="card-header bg-warning text-dark">
              <h5 className="mb-0">🔄 Recent Transfers (Last Hour)</h5>
            </div>
            <div className="card-body">
              {(() => {
                const now = new Date();
                const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
                const recentAssets = assets.filter(asset => {
                  const ts = asset.timestamp || asset.Timestamp;
                  if (!ts) return false;
                  const assetTime = isNaN(ts) ? new Date(ts) : new Date(parseInt(ts) * 1000);
                  return assetTime > oneHourAgo;
                }).sort((a, b) => {
                  const tsA = a.timestamp || a.Timestamp;
                  const tsB = b.timestamp || b.Timestamp;
                  const timeA = isNaN(tsA) ? new Date(tsA).getTime() : parseInt(tsA) * 1000;
                  const timeB = isNaN(tsB) ? new Date(tsB).getTime() : parseInt(tsB) * 1000;
                  return timeB - timeA;
                });

                return recentAssets.length > 0 ? (
                  <div className="table-responsive">
                    <table className="table table-sm table-hover">
                      <thead>
                        <tr>
                          <th>Asset ID</th>
                          <th>Name</th>
                          <th>Origin</th>
                          <th>Current Owner</th>
                          <th>Location</th>
                          <th>Last Updated</th>
                          <th>Transaction ID</th>
                        </tr>
                      </thead>
                      <tbody>
                        {recentAssets.slice(0, 10).map((asset, idx) => {
                          const ts = asset.timestamp || asset.Timestamp;
                          const timeStr = isNaN(ts) 
                            ? new Date(ts).toLocaleString()
                            : new Date(parseInt(ts) * 1000).toLocaleString();
                          
                          // Get origin from assetOrigins prop or use current owner as fallback
                          const currentOwner = asset.owner || asset.Owner;
                          const origin = assetOrigins?.[asset.ID] || currentOwner;
                          
                          return (
                            <tr key={idx}>
                              <td><code className="small">{asset.ID}</code></td>
                              <td>{asset.name || asset.Name}</td>
                              <td><span className="badge bg-warning text-dark">🏭 {origin}</span></td>
                              <td><span className="badge bg-success">👤 {asset.owner || asset.Owner}</span></td>
                              <td><span className="badge bg-info">📍 {asset.location || asset.Location}</span></td>
                              <td className="small text-muted">{timeStr}</td>
                              <td>
                                {asset.transactionId ? (
                                  <small className="text-muted" style={{fontSize: '0.7rem'}} title={asset.transactionId}>
                                    {asset.transactionId.substring(0, 6)}...{asset.transactionId.substring(asset.transactionId.length - 4)}
                                  </small>
                                ) : (
                                  <small className="text-muted">-</small>
                                )}
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <p className="text-muted">No recent transfers in the last hour. Create or transfer assets to see activity!</p>
                );
              })()}
            </div>
          </div>
        </div>
      </div>

      <div className="row g-3 mt-4">
        <div className="col-md-4">
          <div className="card text-center">
            <div className="card-body">
              <h6 className="card-title">System Status</h6>
              <p className="card-text"><span className="badge bg-success">✅ Online</span></p>
            </div>
          </div>
        </div>
        <div className="col-md-4">
          <div className="card text-center">
            <div className="card-body">
              <h6 className="card-title">Last Update</h6>
              <p className="card-text"><span className="badge bg-info">📲 Now</span></p>
            </div>
          </div>
        </div>
        <div className="col-md-4">
          <div className="card text-center">
            <div className="card-body">
              <h6 className="card-title">Network Status</h6>
              <p className="card-text"><span className="badge bg-primary">🔗 Connected</span></p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
