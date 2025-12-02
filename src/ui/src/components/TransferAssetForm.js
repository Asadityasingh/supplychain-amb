import { useState } from 'react';

export default function TransferAssetForm({ assets, onSuccess, onTransactionId }) {
  const [formData, setFormData] = useState({
    assetId: '',
    newOwner: '',
    newLocation: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);
  const [selectedAsset, setSelectedAsset] = useState(null);
  const [transactionId, setTransactionId] = useState(null);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });

    if (name === 'assetId') {
      const asset = assets.find(a => a.ID === value);
      setSelectedAsset(asset || null);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccess(false);

    try {
      const response = await fetch(
        `${process.env.REACT_APP_API_ENDPOINT || 'http://localhost:3001'}/assets/${formData.assetId}/transfer`,
        {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            newOwner: formData.newOwner,
            newLocation: formData.newLocation
          })
        }
      );

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to transfer asset');
      }

      const result = await response.json();
      const txId = result.transactionId;
      setTransactionId(txId);
      setSuccess(true);
      
      // Pass transaction ID to parent
      if (onTransactionId && txId) {
        onTransactionId(formData.assetId, txId);
      }
      
      setFormData({ assetId: '', newOwner: '', newLocation: '' });
      setSelectedAsset(null);
      setTimeout(() => {
        onSuccess();
      }, 1500);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="row justify-content-center">
      <div className="col-lg-8">
        <h2 className="h2 mb-4">🔄 Transfer Asset</h2>

        <div className="card shadow">
          <div className="card-body p-5">
            {error && (
              <div className="alert alert-danger alert-dismissible fade show" role="alert">
                {error}
                <button type="button" className="btn-close" data-bs-dismiss="alert"></button>
              </div>
            )}

            {success && (
              <div className="alert alert-success alert-dismissible fade show" role="alert">
                ✅ Asset transferred successfully!
                {transactionId && <div className="small mt-2">📝 Transaction ID: <code>{transactionId}</code></div>}
                <button type="button" className="btn-close" data-bs-dismiss="alert"></button>
              </div>
            )}

            <form onSubmit={handleSubmit}>
              <div className="mb-3">
                <label className="form-label">Select Asset <span className="text-danger">*</span></label>
                <select
                  name="assetId"
                  value={formData.assetId}
                  onChange={handleChange}
                  required
                  className="form-select"
                >
                  <option value="">Choose an asset...</option>
                  {assets.map(asset => (
                    <option key={asset.ID} value={asset.ID}>
                      {asset.ID} - {asset.name || asset.Name}
                    </option>
                  ))}
                </select>
              </div>

              {selectedAsset && (
                <>
                  <div className="alert alert-info">
                    <h6 className="alert-heading">📋 Current Asset Details</h6>
                    <div className="row g-2 small">
                      <div className="col-md-6">
                        <strong>Name:</strong> {selectedAsset.name || selectedAsset.Name}
                      </div>
                      <div className="col-md-6">
                        <strong>Current Owner:</strong> {selectedAsset.owner || selectedAsset.Owner}
                      </div>
                      <div className="col-md-6">
                        <strong>Current Location:</strong> {selectedAsset.location || selectedAsset.Location}
                      </div>
                      <div className="col-md-6">
                        <strong>Last Updated:</strong> {(() => {
                          const ts = selectedAsset.timestamp || selectedAsset.Timestamp;
                          if (!ts) return 'N/A';
                          const date = isNaN(ts) ? new Date(ts) : new Date(parseInt(ts) * 1000);
                          return date.toLocaleString();
                        })()}
                      </div>
                    </div>
                  </div>

                  <div className="card mb-3">
                    <div className="card-header bg-warning text-dark">
                      <h6 className="mb-0">📜 Transfer History</h6>
                    </div>
                    <div className="card-body">
                      {selectedAsset.history && selectedAsset.history.length > 0 ? (
                        <div className="timeline">
                          {selectedAsset.history.map((entry, idx) => (
                            <div key={idx} className="mb-2 pb-2 border-bottom">
                              <div className="d-flex align-items-start">
                                <span className="badge bg-primary me-2">{idx + 1}</span>
                                <div className="flex-grow-1">
                                  <small className="text-muted">{entry}</small>
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>
                      ) : (
                        <div className="text-center py-3">
                          <p className="text-muted mb-2">📦 Asset Created</p>
                          <small className="text-muted">
                            <strong>Initial Owner:</strong> {selectedAsset.owner || selectedAsset.Owner}<br/>
                            <strong>Initial Location:</strong> {selectedAsset.location || selectedAsset.Location}<br/>
                            <strong>Created:</strong> {(() => {
                              const ts = selectedAsset.timestamp || selectedAsset.Timestamp;
                              if (!ts) return 'N/A';
                              const date = isNaN(ts) ? new Date(ts) : new Date(parseInt(ts) * 1000);
                              return date.toLocaleString();
                            })()}
                          </small>
                          <hr className="my-2"/>
                          <p className="small text-info mb-0">
                            💡 Transfer this asset to see the complete ownership chain!
                          </p>
                        </div>
                      )}
                    </div>
                  </div>
                </>
              )}

              <div className="mb-3">
                <label className="form-label">New Owner <span className="text-danger">*</span></label>
                <input
                  type="text"
                  name="newOwner"
                  value={formData.newOwner}
                  onChange={handleChange}
                  placeholder="e.g., Distributor Co."
                  required
                  className="form-control"
                />
              </div>

              <div className="mb-4">
                <label className="form-label">New Location <span className="text-danger">*</span></label>
                <input
                  type="text"
                  name="newLocation"
                  value={formData.newLocation}
                  onChange={handleChange}
                  placeholder="e.g., Distribution Center B, Delhi"
                  required
                  className="form-control"
                />
              </div>

              <button
                type="submit"
                disabled={loading || !selectedAsset}
                className="btn btn-primary btn-lg w-100 mb-3"
              >
                {loading ? '⏳ Transferring...' : '🔄 Transfer Asset'}
              </button>
            </form>

            <div className="alert alert-info mb-0">
              <strong>💡 Tip:</strong> Select an asset first to see its current details. The transfer will be recorded on the blockchain.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
