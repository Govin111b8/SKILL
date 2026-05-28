import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import {
  FiDownload, FiFilter, FiCalendar, FiCreditCard, FiArrowUp, FiArrowDown,
  FiCheckCircle, FiClock, FiXCircle, FiRefreshCw,
} from 'react-icons/fi';
import { get } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './PaymentHistory.css';

const STATUS_MAP = {
  completed: { label: 'Completed', icon: FiCheckCircle, color: '#10b981' },
  pending: { label: 'Pending', icon: FiClock, color: '#f59e0b' },
  escrow: { label: 'In Escrow', icon: FiClock, color: '#6366f1' },
  released: { label: 'Released', icon: FiCheckCircle, color: '#10b981' },
  refunded: { label: 'Refunded', icon: FiRefreshCw, color: '#8b5cf6' },
  failed: { label: 'Failed', icon: FiXCircle, color: '#ef4444' },
  cod_pending: { label: 'COD Pending', icon: FiClock, color: '#f97316' },
};

export default function PaymentHistory() {
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({});
  const [filters, setFilters] = useState({ from: '', to: '', status: '' });
  const [showFilters, setShowFilters] = useState(false);

  useEffect(() => {
    fetchPayments();
  }, [page, filters]);

  async function fetchPayments() {
    setLoading(true);
    try {
      let url = `/payment-history?page=${page}&limit=15`;
      if (filters.from) url += `&from=${filters.from}`;
      if (filters.to) url += `&to=${filters.to}`;
      if (filters.status) url += `&status=${filters.status}`;
      const res = await get(url);
      setPayments(res.data || []);
      setPagination(res.pagination || {});
    } catch (err) {
      console.error('Failed to load payment history:', err);
    } finally {
      setLoading(false);
    }
  }

  function formatDate(d) {
    return new Date(d).toLocaleDateString('en-IN', {
      day: 'numeric', month: 'short', year: 'numeric',
    });
  }

  function formatAmount(amount) {
    return `₹${parseFloat(amount || 0).toLocaleString('en-IN', { minimumFractionDigits: 0 })}`;
  }

  // Calculate summary
  const totalSpent = payments.filter(p => p.payer_id).reduce((sum, p) => sum + parseFloat(p.amount || 0), 0);
  const totalReceived = payments.filter(p => p.payee_id).reduce((sum, p) => sum + parseFloat(p.amount || 0), 0);

  return (
    <div className="payment-history-page">
      <div className="ph-header">
        <div>
          <h1>Payment History</h1>
          <p>View all your transactions and download invoices</p>
        </div>
        <div className="ph-header-actions">
          <button className="btn btn-outline btn-sm" onClick={() => setShowFilters(!showFilters)}>
            <FiFilter /> Filters
          </button>
        </div>
      </div>

      {showFilters && (
        <div className="ph-filters">
          <div className="ph-filter-group">
            <label>From</label>
            <input type="date" value={filters.from}
              onChange={e => setFilters({ ...filters, from: e.target.value })} />
          </div>
          <div className="ph-filter-group">
            <label>To</label>
            <input type="date" value={filters.to}
              onChange={e => setFilters({ ...filters, to: e.target.value })} />
          </div>
          <div className="ph-filter-group">
            <label>Status</label>
            <select value={filters.status} onChange={e => setFilters({ ...filters, status: e.target.value })}>
              <option value="">All</option>
              <option value="completed">Completed</option>
              <option value="pending">Pending</option>
              <option value="escrow">In Escrow</option>
              <option value="refunded">Refunded</option>
              <option value="failed">Failed</option>
            </select>
          </div>
          <button className="btn btn-sm" onClick={() => { setFilters({ from: '', to: '', status: '' }); setPage(1); }}>
            Clear
          </button>
        </div>
      )}

      {/* Summary Cards */}
      <div className="ph-summary">
        <div className="ph-summary-card">
          <FiArrowUp className="ph-icon sent" />
          <div>
            <span className="ph-summary-label">Total Paid</span>
            <span className="ph-summary-value">{formatAmount(totalSpent)}</span>
          </div>
        </div>
        <div className="ph-summary-card">
          <FiArrowDown className="ph-icon received" />
          <div>
            <span className="ph-summary-label">Total Received</span>
            <span className="ph-summary-value">{formatAmount(totalReceived)}</span>
          </div>
        </div>
        <div className="ph-summary-card">
          <FiCreditCard className="ph-icon" />
          <div>
            <span className="ph-summary-label">Transactions</span>
            <span className="ph-summary-value">{pagination.total || payments.length}</span>
          </div>
        </div>
      </div>

      {loading ? (
        <LoadingSpinner />
      ) : payments.length === 0 ? (
        <div className="ph-empty">
          <FiCreditCard size={48} />
          <h3>No transactions yet</h3>
          <p>Your payment history will appear here</p>
        </div>
      ) : (
        <>
          <div className="ph-list">
            {payments.map(payment => {
              const statusInfo = STATUS_MAP[payment.status] || STATUS_MAP.pending;
              const StatusIcon = statusInfo.icon;
              return (
                <div key={payment.id} className="ph-item">
                  <div className="ph-item-left">
                    <div className="ph-item-icon" style={{ color: statusInfo.color }}>
                      <StatusIcon size={20} />
                    </div>
                    <div className="ph-item-details">
                      <span className="ph-item-title">
                        {payment.booking_title || `Payment #${payment.id?.slice(0, 8)}`}
                      </span>
                      <span className="ph-item-meta">
                        {payment.other_party_name && `with ${payment.other_party_name} • `}
                        {formatDate(payment.created_at)}
                      </span>
                    </div>
                  </div>
                  <div className="ph-item-right">
                    <span className="ph-item-amount">{formatAmount(payment.amount)}</span>
                    <span className="ph-item-status" style={{ color: statusInfo.color }}>
                      {statusInfo.label}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Pagination */}
          {pagination.total_pages > 1 && (
            <div className="ph-pagination">
              <button disabled={page <= 1} onClick={() => setPage(page - 1)} className="btn btn-sm">
                Previous
              </button>
              <span>Page {page} of {pagination.total_pages}</span>
              <button disabled={page >= pagination.total_pages} onClick={() => setPage(page + 1)} className="btn btn-sm">
                Next
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
