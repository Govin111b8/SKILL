import { createContext, useContext, useState, useEffect, useRef, useCallback } from 'react';

const WebSocketContext = createContext(null);

const RECONNECT_BASE_MS = 1000;
const RECONNECT_MAX_MS = 30000;
const HEARTBEAT_INTERVAL_MS = 25000;

let toastIdCounter = 0;

function getToken() {
  return localStorage.getItem('token');
}

function buildWsUrl(token) {
  const proto = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  return `${proto}//${window.location.host}/ws?token=${encodeURIComponent(token)}`;
}

export function WebSocketProvider({ children }) {
  const [connectionState, setConnectionState] = useState('disconnected'); // connecting | connected | disconnected
  const [onlineUsers, setOnlineUsers] = useState({});            // userId -> { status, lastSeen }
  const [unreadNotificationCount, setUnreadNotificationCount] = useState(0);
  const [toasts, setToasts] = useState([]);

  const wsRef = useRef(null);
  const subscribersRef = useRef(new Map()); // type -> Set<callback>
  const reconnectAttemptRef = useRef(0);
  const reconnectTimerRef = useRef(null);
  const heartbeatTimerRef = useRef(null);
  const mountedRef = useRef(true);

  // ── Toast helpers ──────────────────────────────────────────────
  const addToast = useCallback((message, variant = 'info') => {
    const id = `toast-${Date.now()}-${++toastIdCounter}`;
    setToasts((prev) => [...prev, { id, message, variant }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 5000);
  }, []);

  const dismissToast = useCallback((id) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  // ── Subscription system ────────────────────────────────────────
  const subscribe = useCallback((type, callback) => {
    if (!subscribersRef.current.has(type)) {
      subscribersRef.current.set(type, new Set());
    }
    subscribersRef.current.get(type).add(callback);
    return () => {
      const set = subscribersRef.current.get(type);
      if (set) {
        set.delete(callback);
        if (set.size === 0) subscribersRef.current.delete(type);
      }
    };
  }, []);

  const notify = useCallback((type, data) => {
    const set = subscribersRef.current.get(type);
    if (set) {
      set.forEach((cb) => {
        try { cb(data); } catch (err) { console.error('[WebSocket] Subscriber error:', err); }
      });
    }
  }, []);

  // ── Send helpers ───────────────────────────────────────────────
  const send = useCallback((payload) => {
    const ws = wsRef.current;
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify(payload));
      return true;
    }
    return false;
  }, []);

  const sendTyping = useCallback((threadId, to, typing = true) => {
    return send({ type: 'typing', threadId, to, typing });
  }, [send]);

  const sendReadReceipt = useCallback((threadId) => {
    return send({ type: 'read_receipt', threadId });
  }, [send]);

  const sendPresence = useCallback((status) => {
    return send({ type: 'presence', status });
  }, [send]);

  // ── Heartbeat ──────────────────────────────────────────────────
  const startHeartbeat = useCallback(() => {
    stopHeartbeat();
    heartbeatTimerRef.current = setInterval(() => {
      send({ type: 'ping' });
    }, HEARTBEAT_INTERVAL_MS);
  }, [send]);

  const stopHeartbeat = useCallback(() => {
    if (heartbeatTimerRef.current) {
      clearInterval(heartbeatTimerRef.current);
      heartbeatTimerRef.current = null;
    }
  }, []);

  // ── Incoming message dispatch ──────────────────────────────────
  const handleMessage = useCallback((event) => {
    let data;
    try { data = JSON.parse(event.data); } catch { return; }

    const { type } = data;

    // Built-in handling per type
    switch (type) {
      case 'hello':
        break;

      case 'pong':
        break;

      case 'typing':
        break;

      case 'messages_read':
        break;

      case 'booking':
        if (data.action === 'created') {
          addToast('New booking received!', 'success');
        } else if (data.action === 'updated') {
          addToast('Booking updated', 'info');
        }
        break;

      case 'message':
        addToast('New message received', 'info');
        break;

      case 'notification':
        setUnreadNotificationCount((c) => c + 1);
        if (data.title || data.message) {
          addToast(data.title || data.message, 'info');
        }
        break;

      case 'presence_update':
        if (data.userId) {
          setOnlineUsers((prev) => ({
            ...prev,
            [data.userId]: { status: data.status, lastSeen: data.lastSeen },
          }));
        }
        break;

      default:
        break;
    }

    // Fan-out to subscribers
    notify(type, data);
  }, [addToast, notify]);

  // ── Connection management ──────────────────────────────────────
  const connect = useCallback((token) => {
    // Clean up any existing connection
    if (wsRef.current) {
      wsRef.current.onclose = null; // prevent reconnect on intentional close
      wsRef.current.close();
      wsRef.current = null;
    }

    if (!token) {
      setConnectionState('disconnected');
      return;
    }

    setConnectionState('connecting');
    const url = buildWsUrl(token);
    const ws = new WebSocket(url);
    wsRef.current = ws;

    ws.onopen = () => {
      if (!mountedRef.current) return;
      reconnectAttemptRef.current = 0;
      setConnectionState('connected');
      startHeartbeat();
    };

    ws.onmessage = handleMessage;

    ws.onclose = (e) => {
      if (!mountedRef.current) return;
      stopHeartbeat();
      setConnectionState('disconnected');
      wsRef.current = null;

      // Don't reconnect on auth errors
      if (e.code === 4001 || e.code === 4002) return;

      scheduleReconnect(token);
    };

    ws.onerror = () => {
      // onclose will fire after onerror, reconnect handled there
    };
  }, [handleMessage, startHeartbeat, stopHeartbeat]);

  const disconnect = useCallback(() => {
    if (reconnectTimerRef.current) {
      clearTimeout(reconnectTimerRef.current);
      reconnectTimerRef.current = null;
    }
    stopHeartbeat();
    reconnectAttemptRef.current = 0;
    if (wsRef.current) {
      wsRef.current.onclose = null;
      wsRef.current.close();
      wsRef.current = null;
    }
    setConnectionState('disconnected');
  }, [stopHeartbeat]);

  const scheduleReconnect = useCallback((token) => {
    if (reconnectTimerRef.current) return; // already scheduled
    const delay = Math.min(
      RECONNECT_BASE_MS * Math.pow(2, reconnectAttemptRef.current),
      RECONNECT_MAX_MS,
    );
    reconnectAttemptRef.current += 1;
    reconnectTimerRef.current = setTimeout(() => {
      reconnectTimerRef.current = null;
      if (mountedRef.current) connect(token);
    }, delay);
  }, [connect]);

  // ── Auto-connect on token change ──────────────────────────────
  useEffect(() => {
    mountedRef.current = true;
    const token = getToken();
    if (token) {
      connect(token);
    }

    // Watch for storage events (login/logout in another tab)
    const onStorage = (e) => {
      if (e.key === 'token') {
        if (e.newValue) {
          reconnectAttemptRef.current = 0;
          connect(e.newValue);
        } else {
          disconnect();
        }
      }
    };
    window.addEventListener('storage', onStorage);

    return () => {
      mountedRef.current = false;
      window.removeEventListener('storage', onStorage);
      disconnect();
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // Expose a manual reconnect/disconnect for AuthContext integration
  const handleAuthChange = useCallback(() => {
    const token = getToken();
    if (token && connectionState === 'disconnected' && !reconnectTimerRef.current) {
      reconnectAttemptRef.current = 0;
      connect(token);
    } else if (!token) {
      disconnect();
    }
  }, [connect, disconnect, connectionState]);

  // Poll-free detection: listen for custom events dispatched by login/logout
  useEffect(() => {
    const onAuthChange = () => handleAuthChange();
    window.addEventListener('auth-change', onAuthChange);
    return () => window.removeEventListener('auth-change', onAuthChange);
  }, [handleAuthChange]);

  const resetUnreadNotificationCount = useCallback(() => {
    setUnreadNotificationCount(0);
  }, []);

  const value = {
    // Connection
    connectionState,
    isConnected: connectionState === 'connected',

    // Subscriptions
    subscribe,

    // Senders
    send,
    sendTyping,
    sendReadReceipt,
    sendPresence,

    // Presence
    onlineUsers,

    // Notifications
    unreadNotificationCount,
    resetUnreadNotificationCount,

    // Toasts
    toasts,
    dismissToast,

    // Auth integration
    handleAuthChange,
  };

  return (
    <WebSocketContext.Provider value={value}>{children}</WebSocketContext.Provider>
  );
}

export function useWebSocket() {
  const context = useContext(WebSocketContext);
  if (!context) {
    throw new Error('useWebSocket must be used within a WebSocketProvider');
  }
  return context;
}

export default WebSocketContext;
