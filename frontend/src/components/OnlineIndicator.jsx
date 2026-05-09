import { useWebSocket } from '../context/WebSocketContext';
import './OnlineIndicator.css';

function OnlineIndicator({ userId, size = 10, style = {} }) {
  const { onlineUsers } = useWebSocket();
  const isOnline = !!(userId && onlineUsers[userId]?.status === 'online');

  return (
    <span
      className={`online-indicator ${isOnline ? 'online-indicator--online' : 'online-indicator--offline'}`}
      role="status"
      aria-label={isOnline ? 'Online' : 'Offline'}
      style={{
        width: size,
        height: size,
        ...style,
      }}
    />
  );
}

export default OnlineIndicator;
