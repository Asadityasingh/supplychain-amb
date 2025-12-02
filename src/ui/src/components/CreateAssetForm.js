import { useState } from 'react';

export default function CreateAssetForm({ onSuccess, onTransactionId }) {
  const [formData, setFormData] = useState({
    assetId: '',
    name: '',
    location: '',
    owner: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);
  const [transactionId, setTransactionId] = useState(null);

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccess(false);

    try {
      const response = await fetch(
        `${process.env.REACT_APP_API_ENDPOINT || 'http://localhost:3001'}/assets`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(formData)
        }
      );

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to create asset');
      }

      const result = await response.json();
      const txId = result.transactionId;
      setTransactionId(txId);
      setSuccess(true);
      
      // Pass transaction ID to parent
      if (onTransactionId && txId) {
        onTransactionId(formData.assetId, txId);
      }
      
      setFormData({ assetId: '', name: '', location: '', owner: '' });
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
        <h2 className="h2 mb-4">➕ Create New Asset</h2>

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
                ✅ Asset created successfully!
                {transactionId && <div className="small mt-2">📝 Transaction ID: <code>{transactionId}</code></div>}
                <button type="button" className="btn-close" data-bs-dismiss="alert"></button>
              </div>
            )}

            <form onSubmit={handleSubmit}>
              <div className="mb-3">
                <label className="form-label">Asset ID <span className="text-danger">*</span></label>
                <input
                  type="text"
                  name="assetId"
                  value={formData.assetId}
                  onChange={handleChange}
                  placeholder="e.g., ASSET-001"
                  required
                  className="form-control"
                />
              </div>

              <div className="mb-3">
                <label className="form-label">Asset Name <span className="text-danger">*</span></label>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleChange}
                  placeholder="e.g., Pharmaceutical Product X"
                  required
                  className="form-control"
                />
              </div>

              <div className="mb-3">
                <label className="form-label">Initial Location <span className="text-danger">*</span></label>
                <input
                  type="text"
                  name="location"
                  value={formData.location}
                  onChange={handleChange}
                  placeholder="e.g., Warehouse A, Mumbai"
                  required
                  className="form-control"
                />
              </div>

              <div className="mb-4">
                <label className="form-label">Current Owner <span className="text-danger">*</span></label>
                <input
                  type="text"
                  name="owner"
                  value={formData.owner}
                  onChange={handleChange}
                  placeholder="e.g., Manufacturer Ltd"
                  required
                  className="form-control"
                />
              </div>

              <button
                type="submit"
                disabled={loading}
                className="btn btn-primary btn-lg w-100 mb-3"
              >
                {loading ? '⏳ Creating...' : '➕ Create Asset'}
              </button>
            </form>

            <div className="alert alert-info mb-0">
              <strong>💡 Tip:</strong> All fields are required. The asset will be recorded on the blockchain immediately.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
