/**
 * Lazy import with retry — handles chunk load failures gracefully.
 * 
 * When a user has a cached old version of the app and new chunks are deployed,
 * dynamic imports can fail. This utility retries the import with cache-busting,
 * and falls back to a full page reload if all retries fail.
 * 
 * Usage:
 *   const Dashboard = lazy(() => lazyRetry(() => import('./pages/Dashboard')));
 */

/**
 * Wraps a dynamic import with retry logic.
 * @param {() => Promise} importFn - The dynamic import function
 * @param {number} retries - Number of retry attempts (default: 3)
 * @param {number} delay - Delay between retries in ms (default: 1000)
 * @returns {Promise} The module promise
 */
export function lazyRetry(importFn, retries = 3, delay = 1000) {
  return new Promise((resolve, reject) => {
    const attempt = (retriesLeft) => {
      importFn()
        .then(resolve)
        .catch((error) => {
          if (retriesLeft <= 0) {
            // All retries failed — check if we should reload
            const hasReloaded = sessionStorage.getItem('chunk_reload');
            if (!hasReloaded) {
              sessionStorage.setItem('chunk_reload', 'true');
              window.location.reload();
              return;
            }
            // Already tried reloading, surface the error
            sessionStorage.removeItem('chunk_reload');
            reject(error);
            return;
          }

          // Wait and retry
          setTimeout(() => attempt(retriesLeft - 1), delay);
        });
    };

    attempt(retries);
  });
}

// Clear the reload flag on successful page load
if (typeof window !== 'undefined') {
  window.addEventListener('load', () => {
    sessionStorage.removeItem('chunk_reload');
  });
}

export default lazyRetry;
