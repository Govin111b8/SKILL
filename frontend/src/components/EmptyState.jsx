import PropTypes from 'prop-types';
import { FiInbox } from 'react-icons/fi';
import './EmptyState.css';

function EmptyState({ icon: Icon = FiInbox, title = 'Nothing here yet', message = '', action, actionLabel }) {
  return (
    <div className="empty-state">
      <div className="empty-state-icon">
        <Icon size={48} />
      </div>
      <h3 className="empty-state-title">{title}</h3>
      {message && <p className="empty-state-message">{message}</p>}
      {action && actionLabel && (
        <button className="empty-state-action" onClick={action}>
          {actionLabel}
        </button>
      )}
    </div>
  );
}

EmptyState.propTypes = {
  icon: PropTypes.elementType,
  title: PropTypes.string,
  message: PropTypes.string,
  action: PropTypes.func,
  actionLabel: PropTypes.string,
};

export default EmptyState;
