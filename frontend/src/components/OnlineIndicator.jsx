import { useWebSocket } from '../context/WebSocketContext';

function OnlineIndicator({ userId, size = 10, style = {} }) {
  const { onlineUsers } = useWebSocket();
  const isOnline = !!(userId && onlineUsers[userId]?.status === 'online');

  return (
    <span
      className={`online-indicator ${isOnline ? 'online' : 'offline'}`}
      title={isOnline ? 'Online' : 'Offline'}
      style={{
        display: 'inline-block',
        width: size,
        height: size,
        borderRadius: '50%',
        backgroundColor: isOnline ? '#22c55e' : '#9ca3af',
        border: '2px solid #fff',
        flexShrink: 0,
        ...style,
      }}
    />
  );
}

export default OnlineIndicator;
