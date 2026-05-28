/**
 * Form Double-Submit Prevention Hook
 * 
 * Prevents duplicate form submissions by:
 * 1. Disabling the submit action while a request is in-flight
 * 2. Generating idempotency keys for each submission
 * 3. Providing loading state for UI feedback
 * 
 * Usage:
 *   import { useFormSubmit } from '../utils/useFormSubmit';
 *   
 *   function BookingForm() {
 *     const { isSubmitting, submitWithGuard, idempotencyKey } = useFormSubmit();
 *     
 *     const handleSubmit = async (e) => {
 *       e.preventDefault();
 *       await submitWithGuard(async () => {
 *         await api.post('/bookings', data, {
 *           headers: { 'X-Idempotency-Key': idempotencyKey }
 *         });
 *       });
 *     };
 *     
 *     return (
 *       <form onSubmit={handleSubmit}>
 *         <button type="submit" disabled={isSubmitting}>
 *           {isSubmitting ? 'Submitting...' : 'Submit'}
 *         </button>
 *       </form>
 *     );
 *   }
 */

import { useState, useCallback, useRef } from 'react';

/**
 * Generate a unique idempotency key for each form submission.
 */
function generateIdempotencyKey() {
  return `${Date.now()}-${Math.random().toString(36).substring(2, 15)}`;
}

/**
 * Hook that guards against double form submissions.
 * 
 * @param {Object} [options]
 * @param {number} [options.cooldownMs=2000] - Minimum time between submissions
 * @param {Function} [options.onError] - Error handler callback
 * @returns {{ isSubmitting: boolean, submitWithGuard: Function, idempotencyKey: string, reset: Function }}
 */
export function useFormSubmit({ cooldownMs = 2000, onError } = {}) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [idempotencyKey, setIdempotencyKey] = useState(generateIdempotencyKey);
  const lastSubmitRef = useRef(0);

  const reset = useCallback(() => {
    setIsSubmitting(false);
    setIdempotencyKey(generateIdempotencyKey());
  }, []);

  const submitWithGuard = useCallback(async (submitFn) => {
    // Prevent rapid re-submissions
    const now = Date.now();
    if (now - lastSubmitRef.current < cooldownMs) {
      return;
    }

    if (isSubmitting) return;

    setIsSubmitting(true);
    lastSubmitRef.current = now;

    try {
      const result = await submitFn();
      // Generate new idempotency key for next submission
      setIdempotencyKey(generateIdempotencyKey());
      return result;
    } catch (error) {
      if (onError) {
        onError(error);
      }
      throw error;
    } finally {
      setIsSubmitting(false);
    }
  }, [isSubmitting, cooldownMs, onError]);

  return {
    isSubmitting,
    submitWithGuard,
    idempotencyKey,
    reset,
  };
}

export default useFormSubmit;
