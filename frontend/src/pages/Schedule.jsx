import { useState, useEffect, useMemo } from 'react';
import { FiCalendar, FiClock, FiSave, FiX, FiPlus, FiMinus, FiCopy, FiCheck, FiAlertCircle, FiSun, FiMoon } from 'react-icons/fi';
import { get, put, post } from '../api/client';
import { Skeleton } from '../components/Skeleton';
import './Schedule.css';

const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const DAY_SHORT = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const DAY_EMOJIS = ['☀️', '🌙', '🔥', '💪', '⚡', '🎯', '🌟'];

const TIME_OPTIONS = [];
for (let h = 0; h < 24; h++) {
  for (let m = 0; m < 60; m += 30) {
    const val = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
    const hour12 = h === 0 ? 12 : h > 12 ? h - 12 : h;
    const ampm = h < 12 ? 'AM' : 'PM';
    const label = `${hour12}:${String(m).padStart(2, '0')} ${ampm}`;
    TIME_OPTIONS.push({ value: val, label });
  }
}

function Schedule() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [schedule, setSchedule] = useState([]);
  const [blockedDates, setBlockedDates] = useState([]);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [message, setMessage] = useState(null);
  const [newBlockDate, setNewBlockDate] = useState('');
  const [blockReason, setBlockReason] = useState('');
  const [copySource, setCopySource] = useState(null);

  useEffect(() => {
    fetchData();
  }, []);

  // Clear messages after 4s
  useEffect(() => {
    if (message) {
      const t = setTimeout(() => setMessage(null), 4000);
      return () => clearTimeout(t);
    }
  }, [message]);

  async function fetchData() {
    try {
      const [schedRes, blockedRes] = await Promise.all([
        get('/schedule'),
        get('/schedule/blocked')
      ]);
      setSchedule((schedRes.data || schedRes).schedule || []);
      setBlockedDates((blockedRes.data || blockedRes).blocked_dates || []);
      setError(null);
    } catch (err) {
      setError('Failed to load schedule. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  // Conflict detection
  const conflicts = useMemo(() => {
    const issues = [];
    DAYS.forEach((day, dayIdx) => {
      const daySlots = schedule.filter(s => s.day_of_week === dayIdx && s.is_active);
      for (let i = 0; i < daySlots.length; i++) {
        for (let j = i + 1; j < daySlots.length; j++) {
          if (daySlots[i].start_time < daySlots[j].end_time && daySlots[j].start_time < daySlots[i].end_time) {
            issues.push({ day, dayIdx, msg: `Overlapping slots on ${day}` });
          }
        }
        if (daySlots[i].start_time >= daySlots[i].end_time) {
          issues.push({ day, dayIdx, msg: `Start time must be before end time on ${day}` });
        }
      }
    });
    return issues;
  }, [schedule]);

  function addSlot(dayOfWeek) {
    setSchedule(prev => [...prev, {
      day_of_week: dayOfWeek,
      start_time: '09:00',
      end_time: '17:00',
      is_active: true,
      _isNew: true
    }]);
  }

  function removeSlot(index) {
    setSchedule(prev => prev.filter((_, i) => i !== index));
  }

  function updateSlot(index, field, value) {
    setSchedule(prev => prev.map((s, i) => i === index ? { ...s, [field]: value } : s));
  }

  function copyDay(dayIndex) {
    setCopySource(dayIndex);
    setMessage({ type: 'info', text: `Select a day to paste ${DAYS[dayIndex]}'s schedule` });
  }

  function pasteDay(dayIndex) {
    if (copySource === null || copySource === dayIndex) return;
    const sourceSlots = schedule.filter(s => s.day_of_week === copySource);
    const withoutTarget = schedule.filter(s => s.day_of_week !== dayIndex);
    const copiedSlots = sourceSlots.map(s => ({ ...s, day_of_week: dayIndex, _isNew: true }));
    setSchedule([...withoutTarget, ...copiedSlots]);
    setCopySource(null);
    setMessage({ type: 'success', text: `Copied ${DAYS[copySource]}'s schedule to ${DAYS[dayIndex]}` });
  }

  function toggleDayOff(dayIndex) {
    const daySlots = schedule.filter(s => s.day_of_week === dayIndex);
    if (daySlots.length > 0) {
      // Remove all slots for this day
      setSchedule(prev => prev.filter(s => s.day_of_week !== dayIndex));
    } else {
      addSlot(dayIndex);
    }
  }

  async function saveSchedule() {
    if (conflicts.length > 0) {
      setMessage({ type: 'error', text: 'Fix schedule conflicts before saving' });
      return;
    }
    setSaving(true);
    setMessage(null);
    try {
      const slots = schedule.map(s => ({
        day_of_week: s.day_of_week,
        start_time: s.start_time,
        end_time: s.end_time,
        is_active: s.is_active
      }));
      await put('/schedule', { slots });
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
      setMessage({ type: 'success', text: 'Schedule saved successfully! ✨' });
      fetchData();
    } catch (err) {
      setMessage({ type: 'error', text: 'Error saving schedule: ' + err.message });
    } finally {
      setSaving(false);
    }
  }

  async function addBlockedDate() {
    if (!newBlockDate) return;
    try {
      await post('/schedule/block', { dates: [newBlockDate], reason: blockReason || 'Day off' });
      setNewBlockDate('');
      setBlockReason('');
      setMessage({ type: 'success', text: 'Date blocked 🚫' });
      fetchData();
    } catch (err) {
      setMessage({ type: 'error', text: 'Error blocking date: ' + err.message });
    }
  }

  async function removeBlockedDate(date) {
    try {
      await post('/schedule/unblock', { dates: [date] });
      setMessage({ type: 'success', text: 'Date unblocked ✅' });
      fetchData();
    } catch (err) {
      setMessage({ type: 'error', text: 'Error: ' + err.message });
    }
  }

  // Calculate total weekly hours
  const totalHours = useMemo(() => {
    let total = 0;
    schedule.filter(s => s.is_active).forEach(s => {
      const [sh, sm] = s.start_time.split(':').map(Number);
      const [eh, em] = s.end_time.split(':').map(Number);
      total += (eh * 60 + em - sh * 60 - sm) / 60;
    });
    return Math.max(0, total).toFixed(1);
  }, [schedule]);

  const activeDays = useMemo(() => {
    const days = new Set(schedule.filter(s => s.is_active).map(s => s.day_of_week));
    return days.size;
  }, [schedule]);

  if (loading) {
    return (
      <div className="schedule-page">
        <div className="container">
          <Skeleton width="250px" height="2rem" />
          <div style={{ marginTop: '0.5rem' }}><Skeleton width="350px" height="1rem" /></div>
          <div style={{ marginTop: '2rem', display: 'flex', gap: '1rem' }}>
            <Skeleton width="120px" height="80px" borderRadius="12px" />
            <Skeleton width="120px" height="80px" borderRadius="12px" />
            <Skeleton width="120px" height="80px" borderRadius="12px" />
          </div>
          <div style={{ marginTop: '1.5rem' }}>
            <Skeleton count={7} height="60px" borderRadius="12px" />
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="schedule-page">
        <div className="container">
          <div className="schedule-error">
            <FiAlertCircle size={48} />
            <h2>Unable to load schedule</h2>
            <p>{error}</p>
            <button className="btn btn-primary" onClick={() => { setLoading(true); fetchData(); }}>
              Try Again
            </button>
          </div>
        </div>
      </div>
    );
  }

  const scheduleByDay = DAYS.map((day, i) => ({
    day,
    dayIndex: i,
    short: DAY_SHORT[i],
    emoji: DAY_EMOJIS[i],
    slots: schedule.filter(s => s.day_of_week === i),
    hasConflict: conflicts.some(c => c.dayIdx === i)
  }));

  return (
    <div className="schedule-page">
      <div className="container">
        {/* Header */}
        <div className="schedule-header">
          <div className="schedule-header__info">
            <h1>📅 Availability Schedule</h1>
            <p className="schedule-header__subtitle">Set your weekly working hours and manage time off</p>
          </div>
          <button
            className={`schedule-save-btn ${saved ? 'saved' : ''}`}
            onClick={saveSchedule}
            disabled={saving || conflicts.length > 0}
            aria-label="Save schedule"
          >
            {saving ? (
              <><span className="schedule-save-spinner" /> Saving...</>
            ) : saved ? (
              <><FiCheck size={16} /> Saved!</>
            ) : (
              <><FiSave size={16} /> Save Schedule</>
            )}
          </button>
        </div>

        {/* Stats cards */}
        <div className="schedule-stats">
          <div className="schedule-stat">
            <FiClock size={20} className="schedule-stat__icon" />
            <div>
              <span className="schedule-stat__value">{totalHours}h</span>
              <span className="schedule-stat__label">Weekly Hours</span>
            </div>
          </div>
          <div className="schedule-stat">
            <FiCalendar size={20} className="schedule-stat__icon" />
            <div>
              <span className="schedule-stat__value">{activeDays}</span>
              <span className="schedule-stat__label">Active Days</span>
            </div>
          </div>
          <div className="schedule-stat">
            <FiMoon size={20} className="schedule-stat__icon" />
            <div>
              <span className="schedule-stat__value">{blockedDates.length}</span>
              <span className="schedule-stat__label">Blocked Dates</span>
            </div>
          </div>
        </div>

        {/* Toast message */}
        {message && (
          <div className={`schedule-toast schedule-toast--${message.type}`} role="alert">
            {message.type === 'success' && <FiCheck size={16} />}
            {message.type === 'error' && <FiAlertCircle size={16} />}
            {message.type === 'info' && <FiCopy size={16} />}
            <span>{message.text}</span>
            <button onClick={() => setMessage(null)} aria-label="Dismiss" className="schedule-toast__close">
              <FiX size={14} />
            </button>
          </div>
        )}

        {/* Conflicts warning */}
        {conflicts.length > 0 && (
          <div className="schedule-conflicts" role="alert">
            <FiAlertCircle size={18} />
            <div>
              <strong>Schedule Conflicts</strong>
              {conflicts.map((c, i) => <p key={i}>{c.msg}</p>)}
            </div>
          </div>
        )}

        {/* Weekly Schedule */}
        <div className="schedule-section">
          <div className="schedule-section__header">
            <h2><FiSun size={20} /> Weekly Hours</h2>
            <span className="schedule-timezone">🕐 {Intl.DateTimeFormat().resolvedOptions().timeZone}</span>
          </div>

          <div className="week-schedule">
            {scheduleByDay.map(({ day, dayIndex, short, emoji, slots, hasConflict }) => (
              <div
                key={dayIndex}
                className={`day-card ${slots.length === 0 ? 'day-card--off' : ''} ${hasConflict ? 'day-card--conflict' : ''} ${copySource !== null && copySource !== dayIndex ? 'day-card--paste-target' : ''}`}
                onClick={copySource !== null ? () => pasteDay(dayIndex) : undefined}
                role={copySource !== null ? 'button' : undefined}
                tabIndex={copySource !== null ? 0 : undefined}
              >
                <div className="day-card__header">
                  <div className="day-card__title">
                    <span className="day-card__emoji">{emoji}</span>
                    <span className="day-card__name">{day}</span>
                    <span className="day-card__short">{short}</span>
                  </div>
                  <div className="day-card__actions">
                    {slots.length > 0 && (
                      <button
                        className="day-card__action"
                        onClick={(e) => { e.stopPropagation(); copyDay(dayIndex); }}
                        title={`Copy ${day}'s schedule`}
                        aria-label={`Copy ${day}'s schedule to another day`}
                      >
                        <FiCopy size={13} />
                      </button>
                    )}
                    <button
                      className="day-card__action"
                      onClick={(e) => { e.stopPropagation(); addSlot(dayIndex); }}
                      title="Add time slot"
                      aria-label={`Add time slot for ${day}`}
                    >
                      <FiPlus size={14} />
                    </button>
                  </div>
                </div>

                <div className="day-card__slots">
                  {slots.length === 0 ? (
                    <button className="day-card__add-first" onClick={(e) => { e.stopPropagation(); addSlot(dayIndex); }}>
                      <FiPlus size={14} />
                      <span>Add working hours</span>
                    </button>
                  ) : (
                    slots.map((slot) => {
                      const globalIdx = schedule.indexOf(slot);
                      const startLabel = TIME_OPTIONS.find(t => t.value === slot.start_time)?.label || slot.start_time;
                      const endLabel = TIME_OPTIONS.find(t => t.value === slot.end_time)?.label || slot.end_time;
                      return (
                        <div key={globalIdx} className={`slot-chip ${!slot.is_active ? 'slot-chip--inactive' : ''}`}>
                          <div className="slot-chip__times">
                            <select
                              value={slot.start_time}
                              onChange={e => updateSlot(globalIdx, 'start_time', e.target.value)}
                              className="slot-chip__select"
                              aria-label={`${day} start time`}
                              onClick={e => e.stopPropagation()}
                            >
                              {TIME_OPTIONS.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
                            </select>
                            <span className="slot-chip__sep">→</span>
                            <select
                              value={slot.end_time}
                              onChange={e => updateSlot(globalIdx, 'end_time', e.target.value)}
                              className="slot-chip__select"
                              aria-label={`${day} end time`}
                              onClick={e => e.stopPropagation()}
                            >
                              {TIME_OPTIONS.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
                            </select>
                          </div>
                          <div className="slot-chip__controls">
                            <button
                              className={`slot-chip__toggle ${slot.is_active ? 'active' : ''}`}
                              onClick={(e) => { e.stopPropagation(); updateSlot(globalIdx, 'is_active', !slot.is_active); }}
                              aria-label={slot.is_active ? 'Deactivate slot' : 'Activate slot'}
                              title={slot.is_active ? 'Active' : 'Inactive'}
                            >
                              <span className="slot-chip__toggle-dot" />
                            </button>
                            <button
                              className="slot-chip__remove"
                              onClick={(e) => { e.stopPropagation(); removeSlot(globalIdx); }}
                              aria-label={`Remove time slot from ${day}`}
                              title="Remove slot"
                            >
                              <FiX size={13} />
                            </button>
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Blocked Dates */}
        <div className="schedule-section">
          <div className="schedule-section__header">
            <h2>🏖️ Blocked Dates</h2>
            <span className="blocked-count">{blockedDates.length} blocked</span>
          </div>

          <div className="block-date-form">
            <div className="block-date-form__inputs">
              <div className="block-date-input-wrap">
                <label htmlFor="block-date" className="sr-only">Select date to block</label>
                <input
                  id="block-date"
                  type="date"
                  value={newBlockDate}
                  onChange={e => setNewBlockDate(e.target.value)}
                  min={new Date().toISOString().split('T')[0]}
                  className="block-date-input"
                  aria-label="Date to block"
                />
              </div>
              <div className="block-date-input-wrap">
                <label htmlFor="block-reason" className="sr-only">Reason for blocking</label>
                <input
                  id="block-reason"
                  type="text"
                  value={blockReason}
                  onChange={e => setBlockReason(e.target.value)}
                  placeholder="Reason (e.g. Vacation 🏖️)"
                  className="block-date-input"
                  aria-label="Reason for blocking"
                />
              </div>
            </div>
            <button className="block-date-btn" onClick={addBlockedDate} disabled={!newBlockDate}>
              <FiPlus size={14} /> Block Date
            </button>
          </div>

          {blockedDates.length > 0 ? (
            <div className="blocked-list">
              {blockedDates.map((bd) => (
                <div key={bd.id} className="blocked-chip">
                  <span className="blocked-chip__date">
                    📅 {new Date(bd.blocked_date).toLocaleDateString('en-IN', { weekday: 'short', month: 'short', day: 'numeric' })}
                  </span>
                  {bd.reason && <span className="blocked-chip__reason">{bd.reason}</span>}
                  <button
                    className="blocked-chip__remove"
                    onClick={() => removeBlockedDate(bd.blocked_date)}
                    aria-label={`Unblock ${bd.blocked_date}`}
                    title="Unblock date"
                  >
                    <FiX size={13} />
                  </button>
                </div>
              ))}
            </div>
          ) : (
            <div className="blocked-empty">
              <FiCalendar size={32} />
              <p>No blocked dates</p>
              <span>Add dates when you're unavailable (vacation, personal days, etc.)</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default Schedule;
