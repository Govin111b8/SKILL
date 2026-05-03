import { useState, useEffect } from 'react';
import { FiX, FiDownload, FiSmartphone } from 'react-icons/fi';
import './AppInstallBanner.css';

function AppInstallBanner() {
  const [visible, setVisible] = useState(false);
  const [deferredPrompt, setDeferredPrompt] = useState(null);

  useEffect(() => {
    // Check if user dismissed before
    const dismissed = localStorage.getItem('sc_app_banner_dismissed');
    if (dismissed) return;

    // Listen for PWA install prompt
    function handleBeforeInstall(e) {
      e.preventDefault();
      setDeferredPrompt(e);
      setVisible(true);
    }

    window.addEventListener('beforeinstallprompt', handleBeforeInstall);

    // Also show banner on mobile browsers without PWA support
    const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
    const isStandalone = window.matchMedia('(display-mode: standalone)').matches;
    if (isMobile && !isStandalone) {
      setTimeout(() => setVisible(true), 5000); // Show after 5s on mobile
    }

    return () => window.removeEventListener('beforeinstallprompt', handleBeforeInstall);
  }, []);

  async function handleInstall() {
    if (deferredPrompt) {
      deferredPrompt.prompt();
      const { outcome } = await deferredPrompt.userChoice;
      if (outcome === 'accepted') {
        setVisible(false);
      }
      setDeferredPrompt(null);
    } else {
      // Redirect to app download
      window.open('/api/download/apk', '_blank');
    }
  }

  function handleDismiss() {
    setVisible(false);
    localStorage.setItem('sc_app_banner_dismissed', Date.now().toString());
  }

  if (!visible) return null;

  return (
    <div className="app-install-banner">
      <div className="aib-content">
        <div className="aib-icon">
          <FiSmartphone size={20} />
        </div>
        <div className="aib-text">
          <strong>Get the SkillConnect App</strong>
          <span>Book faster, get notifications & exclusive app-only deals</span>
        </div>
        <button className="aib-install-btn" onClick={handleInstall}>
          <FiDownload size={14} /> Install
        </button>
        <button className="aib-close" onClick={handleDismiss} aria-label="Close">
          <FiX size={16} />
        </button>
      </div>
    </div>
  );
}

export default AppInstallBanner;
