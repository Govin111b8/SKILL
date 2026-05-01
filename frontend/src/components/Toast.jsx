import { FiCheck, FiInfo, FiAlertTriangle, FiXCircle, FiX } from 'react-icons/fi';
import { useWebSocket } from '../context/WebSocketContext';
import './Toast.css';

const VARIANT_ICON = {
  success: FiCheck,
  info: FiInfo,
  warning: FiAlertTriangle,
  error: FiXCircle,
};

function Toast() {
  const { toasts, dismissToast } = useWebSocket();

  if (!toasts || toasts.length === 0) return null;

  return (
    <div className="toast-container" aria-live="polite">
      {toasts.map((toast) => {
        const Icon = VARIANT_ICON[toast.variant] || FiInfo;
        return (
          <div
            key={toast.id}
            className={`toast toast--${toast.variant || 'info'}`}
            onClick={() => dismissToast(toast.id)}
            role="alert"
          >
            <div className="toast-icon">
              <Icon size={16} />
            </div>
            <span className="toast-message">{toast.message}</span>
            <button
              className="toast-close"
              onClick={(e) => {
                e.stopPropagation();
                dismissToast(toast.id);
              }}
              aria-label="Dismiss"
            >
              <FiX size={14} />
            </button>
            <div className="toast-progress">
              <div className="toast-progress-bar" />
            </div>
          </div>
        );
      })}
    </div>
  );
}

export default Toast;
