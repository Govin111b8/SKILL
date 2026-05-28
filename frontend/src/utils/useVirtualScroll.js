/**
 * Virtual scrolling hook for rendering large lists efficiently.
 * 
 * Only renders items visible in the viewport (plus a buffer),
 * dramatically reducing DOM nodes for long lists like bookings,
 * search results, and messages.
 * 
 * Usage:
 *   import { useVirtualScroll } from '../utils/useVirtualScroll';
 *   
 *   function BookingsList({ bookings }) {
 *     const { containerRef, virtualItems, totalHeight, offsetTop } = useVirtualScroll({
 *       items: bookings,
 *       itemHeight: 80,
 *       overscan: 5,
 *     });
 *     
 *     return (
 *       <div ref={containerRef} style={{ height: '600px', overflow: 'auto' }}>
 *         <div style={{ height: totalHeight, position: 'relative' }}>
 *           <div style={{ transform: `translateY(${offsetTop}px)` }}>
 *             {virtualItems.map(item => (
 *               <BookingCard key={item.id} booking={item} />
 *             ))}
 *           </div>
 *         </div>
 *       </div>
 *     );
 *   }
 */

import { useState, useRef, useEffect, useCallback, useMemo } from 'react';

/**
 * @param {Object} options
 * @param {Array} options.items - The full list of items
 * @param {number} options.itemHeight - Height of each item in pixels
 * @param {number} [options.overscan=5] - Number of extra items to render above/below viewport
 * @param {number} [options.containerHeight] - Fixed container height (auto-detected if ref used)
 */
export function useVirtualScroll({ items, itemHeight, overscan = 5, containerHeight: fixedHeight }) {
  const containerRef = useRef(null);
  const [scrollTop, setScrollTop] = useState(0);
  const [containerHeight, setContainerHeight] = useState(fixedHeight || 600);

  // Update container height on resize
  useEffect(() => {
    if (fixedHeight) {
      setContainerHeight(fixedHeight);
      return;
    }

    const container = containerRef.current;
    if (!container) return;

    const updateHeight = () => setContainerHeight(container.clientHeight);
    updateHeight();

    const observer = new ResizeObserver(updateHeight);
    observer.observe(container);
    return () => observer.disconnect();
  }, [fixedHeight]);

  // Scroll handler
  const handleScroll = useCallback((e) => {
    setScrollTop(e.target.scrollTop);
  }, []);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    container.addEventListener('scroll', handleScroll, { passive: true });
    return () => container.removeEventListener('scroll', handleScroll);
  }, [handleScroll]);

  // Calculate visible range
  const { virtualItems, totalHeight, offsetTop, startIndex, endIndex } = useMemo(() => {
    const totalHeight = items.length * itemHeight;
    const startIndex = Math.max(0, Math.floor(scrollTop / itemHeight) - overscan);
    const visibleCount = Math.ceil(containerHeight / itemHeight);
    const endIndex = Math.min(items.length - 1, startIndex + visibleCount + overscan * 2);

    const virtualItems = items.slice(startIndex, endIndex + 1);
    const offsetTop = startIndex * itemHeight;

    return { virtualItems, totalHeight, offsetTop, startIndex, endIndex };
  }, [items, itemHeight, scrollTop, containerHeight, overscan]);

  return {
    containerRef,
    virtualItems,
    totalHeight,
    offsetTop,
    startIndex,
    endIndex,
    scrollTop,
  };
}

export default useVirtualScroll;
