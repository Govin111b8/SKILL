/**
 * React hook for automatic AbortController cleanup on component unmount.
 * 
 * Prevents memory leaks and React "Can't perform a state update on an
 * unmounted component" warnings by aborting in-flight API requests when
 * the component unmounts.
 * 
 * Usage:
 *   import { useAbortController, useAbortableEffect } from '../utils/useAbortController';
 *   
 *   // Option 1: Manual usage
 *   function MyComponent() {
 *     const getSignal = useAbortController();
 *     
 *     const fetchData = async () => {
 *       const res = await api.get('/data', { signal: getSignal() });
 *       setData(res.data);
 *     };
 *   }
 *   
 *   // Option 2: Effect-based (auto-abort on cleanup)
 *   function MyComponent() {
 *     useAbortableEffect((signal) => {
 *       api.get('/data', { signal })
 *         .then(res => setData(res.data))
 *         .catch(err => { if (!signal.aborted) setError(err); });
 *     }, [dependency]);
 *   }
 */

import { useRef, useEffect, useCallback } from 'react';

/**
 * Returns a function that creates a new AbortSignal each time it's called.
 * Previous signals are automatically aborted when a new one is created or
 * when the component unmounts.
 */
export function useAbortController() {
  const controllerRef = useRef(null);

  // Abort on unmount
  useEffect(() => {
    return () => {
      if (controllerRef.current) {
        controllerRef.current.abort();
      }
    };
  }, []);

  const getSignal = useCallback(() => {
    // Abort any previous request
    if (controllerRef.current) {
      controllerRef.current.abort();
    }
    controllerRef.current = new AbortController();
    return controllerRef.current.signal;
  }, []);

  return getSignal;
}

/**
 * Like useEffect, but provides an AbortSignal that is automatically
 * aborted when the effect is cleaned up (deps change or unmount).
 * 
 * @param {(signal: AbortSignal) => void} effect - Effect function receiving an AbortSignal
 * @param {Array} deps - Dependency array (same as useEffect)
 */
export function useAbortableEffect(effect, deps) {
  useEffect(() => {
    const controller = new AbortController();
    effect(controller.signal);
    return () => controller.abort();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);
}

export default { useAbortController, useAbortableEffect };
