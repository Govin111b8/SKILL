import { useState, useEffect } from 'react';
import { FiCalendar, FiClock, FiSave, FiX, FiPlus, FiMinus } from 'react-icons/fi';
import { get, put, post } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './Schedule.css';

const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const HOURS = Array.from({ length: 24 }, (_, i) => `${String(i).padStart(2, '0')}:00`);

function Schedule() {
  const [loading, setLoading] = useState(true);
  const [schedule, setSchedule] = useState([]);
  const [blockedDates, setBlockedDates] = useState([]);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [newBlockDate, setNewBlockDate] = useState('');
  const [blockReason, setBlockReason] = useState('');

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    try {
      const [schedRes, blockedRes] = await Promise.all([
        get('/schedule'),
        get('/schedule/blocked')
      ]);
      setSchedule((schedRes.data || schedRes).schedule || []);
      setBlockedDates((blockedRes.data || blockedRes).blocked_dates || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

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

  async function saveSchedule() {
    setSaving(true);
    setMessage('');
    try {
      const slots = schedule.map(s => ({
        day_of_week: s.day_of_week,
        start_time: s.start_time,
        end_time: s.end_time,
        is_active: s.is_active
      }));
      await put('/schedule', { slots });
      setMessage('Schedule saved successfully!');
      fetchData();
    } catch (err) {
      setMessage('Error saving schedule: ' + err.message);
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
      fetchData();
    } catch (err) {
      setMessage('Error blocking date: ' + err.message);
    }
  }

  async function removeBlockedDate(date) {
    try {
      await post('/schedule/unblock', { dates: [date] });
      fetchData();
    } catch (err) {
      setMessage('Error: ' + err.message);
    }
  }

  if (loading) return <LoadingSpinner />;

  // Group schedule by day
  const scheduleByDay = DAYS.map((day, i) => ({
    day,
    dayIndex: i,
    slots: schedule.filter(s => s.day_of_week === i)
  }));

  return (
    <div className="schedule-page">
      <div className="container">
        <div className="page-header">
          <h1><FiCalendar /> Availability Schedule</h1>
          <p className="page-subtitle">Set your weekly working hours and block specific dates</p>
        </div>

        {message && <div className={`alert ${message.includes('Error') ? 'alert--error' : 'alert--success'}`}>{message}</div>}

        {/* Weekly Schedule */}
        <div className="schedule-section">
          <div className="section-header">
            <h2><FiClock /> Weekly Hours</h2>
            <button className="btn btn-primary btn-sm" onClick={saveSchedule} disabled={saving}>
              <FiSave /> {saving ? 'Saving...' : 'Save Schedule'}
            </button>
          </div>

          <div className="week-schedule">
            {scheduleByDay.map(({ day, dayIndex, slots }) => (
              <div key={dayIndex} className="day-row">
                <div className="day-label">
                  <span className="day-name">{day}</span>
                  <button className="btn-icon btn-icon--sm" onClick={() => addSlot(dayIndex)} title="Add slot">
                    <FiPlus size={14} />
                  </button>
                </div>
                <div className="day-slots">
                  {slots.length === 0 ? (
                    <span className="day-off">Day off</span>
                  ) : (
                    slots.map((slot, slotIdx) => {
                      const globalIdx = schedule.indexOf(slot);
                      return (
                        <div key={slotIdx} className="slot-row">
                          <select
                            value={slot.start_time}
                            onChange={e => updateSlot(globalIdx, 'start_time', e.target.value)}
                            className="time-select"
                          >
                            {HOURS.map(h => <option key={h} value={h}>{h}</option>)}
                          </select>
                          <span className="slot-separator">to</span>
                          <select
                            value={slot.end_time}
                            onChange={e => updateSlot(globalIdx, 'end_time', e.target.value)}
                            className="time-select"
                          >
                            {HOURS.map(h => <option key={h} value={h}>{h}</option>)}
                          </select>
                          <label className="slot-toggle">
                            <input
                              type="checkbox"
                              checked={slot.is_active}
                              onChange={e => updateSlot(globalIdx, 'is_active', e.target.checked)}
                            />
                            <span className="toggle-label">{slot.is_active ? 'Active' : 'Off'}</span>
                          </label>
                          <button className="btn-icon btn-icon--danger" onClick={() => removeSlot(globalIdx)} title="Remove">
                            <FiX size={14} />
                          </button>
                        </div>
                      );
                    })
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Blocked Dates (Vacation) */}
        <div className="schedule-section">
          <h2><FiX /> Blocked Dates (Vacation / Days Off)</h2>
          <div className="block-date-form">
            <input
              type="date"
              value={newBlockDate}
              onChange={e => setNewBlockDate(e.target.value)}
              min={new Date().toISOString().split('T')[0]}
              className="form-input"
            />
            <input
              type="text"
              value={blockReason}
              onChange={e => setBlockReason(e.target.value)}
              placeholder="Reason (optional)"
              className="form-input"
            />
            <button className="btn btn-primary btn-sm" onClick={addBlockedDate} disabled={!newBlockDate}>
              <FiPlus /> Block Date
            </button>
          </div>

          {blockedDates.length > 0 ? (
            <div className="blocked-list">
              {blockedDates.map((bd) => (
                <div key={bd.id} className="blocked-item">
                  <span className="blocked-date">{new Date(bd.blocked_date).toLocaleDateString('en-IN', { weekday: 'short', month: 'short', day: 'numeric' })}</span>
                  <span className="blocked-reason">{bd.reason}</span>
                  <button className="btn-icon btn-icon--danger" onClick={() => removeBlockedDate(bd.blocked_date)} title="Unblock">
                    <FiMinus size={14} />
                  </button>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-muted">No blocked dates. Add dates when you're unavailable.</p>
          )}
        </div>
      </div>
    </div>
  );
}

export default Schedule;
