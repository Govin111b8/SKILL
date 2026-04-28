/**
 * Booking FSM unit tests
 * Validates the state machine matrix and role gating without touching the database.
 */
const { FSM, PRO_ONLY, CUSTOMER_ONLY } = require('../src/controllers/bookingController');

describe('Booking FSM', () => {
  test('every state is defined', () => {
    const states = ['requested','quoted','accepted','scheduled','in_progress','completed','cancelled','disputed','refunded'];
    for (const s of states) expect(FSM).toHaveProperty(s);
  });

  test('happy path transitions are allowed', () => {
    expect(FSM.requested).toContain('quoted');
    expect(FSM.quoted).toContain('accepted');
    expect(FSM.accepted).toContain('scheduled');
    expect(FSM.scheduled).toContain('in_progress');
    expect(FSM.in_progress).toContain('completed');
  });

  test('cannot skip states', () => {
    expect(FSM.requested).not.toContain('accepted');
    expect(FSM.requested).not.toContain('scheduled');
    expect(FSM.requested).not.toContain('completed');
    expect(FSM.quoted).not.toContain('scheduled');
    expect(FSM.accepted).not.toContain('completed');
    expect(FSM.scheduled).not.toContain('completed');
  });

  test('cancellation is allowed pre-completion', () => {
    expect(FSM.requested).toContain('cancelled');
    expect(FSM.quoted).toContain('cancelled');
    expect(FSM.accepted).toContain('cancelled');
    expect(FSM.scheduled).toContain('cancelled');
    expect(FSM.in_progress).toContain('cancelled');
  });

  test('completed jobs cannot be cancelled', () => {
    expect(FSM.completed).not.toContain('cancelled');
  });

  test('terminal states have no exits', () => {
    expect(FSM.cancelled).toHaveLength(0);
    expect(FSM.refunded).toHaveLength(0);
  });

  test('disputes can be raised from active or completed states', () => {
    expect(FSM.in_progress).toContain('disputed');
    expect(FSM.completed).toContain('disputed');
    expect(FSM.requested).not.toContain('disputed');
  });

  test('disputes can be resolved by refund or completion', () => {
    expect(FSM.disputed).toContain('refunded');
    expect(FSM.disputed).toContain('completed');
  });

  test('refund is reachable only from completed or disputed', () => {
    const reachable = Object.entries(FSM).filter(([_, v]) => v.includes('refunded')).map(([k]) => k);
    expect(reachable.sort()).toEqual(['completed', 'disputed']);
  });
});

describe('Role gating', () => {
  test('only pro can quote, start, complete', () => {
    expect(PRO_ONLY).toEqual(expect.arrayContaining(['quoted', 'in_progress', 'completed']));
  });

  test('only customer can accept', () => {
    expect(CUSTOMER_ONLY).toEqual(['accepted']);
  });

  test('cancel is not role-gated (both sides may cancel)', () => {
    expect(PRO_ONLY).not.toContain('cancelled');
    expect(CUSTOMER_ONLY).not.toContain('cancelled');
  });

  test('schedule is not role-gated (either side may propose, but typically pro)', () => {
    // Currently allowed from either side; documented intent
    expect(PRO_ONLY).not.toContain('scheduled');
    expect(CUSTOMER_ONLY).not.toContain('scheduled');
  });
});

describe('Transition validation helper', () => {
  function canTransition(from, to, role) {
    if (!FSM[from] || !FSM[from].includes(to)) return false;
    if (PRO_ONLY.includes(to) && role !== 'pro') return false;
    if (CUSTOMER_ONLY.includes(to) && role !== 'customer') return false;
    return true;
  }

  test('customer accept after quote', () => {
    expect(canTransition('quoted', 'accepted', 'customer')).toBe(true);
    expect(canTransition('quoted', 'accepted', 'pro')).toBe(false);
  });

  test('pro completes job', () => {
    expect(canTransition('in_progress', 'completed', 'pro')).toBe(true);
    expect(canTransition('in_progress', 'completed', 'customer')).toBe(false);
  });

  test('blocked invalid jumps', () => {
    expect(canTransition('requested', 'completed', 'pro')).toBe(false);
    expect(canTransition('completed', 'requested', 'customer')).toBe(false);
    expect(canTransition('cancelled', 'requested', 'customer')).toBe(false);
  });

  test('full happy path is reachable', () => {
    const path = [
      ['requested', 'quoted', 'pro'],
      ['quoted', 'accepted', 'customer'],
      ['accepted', 'scheduled', 'pro'],
      ['scheduled', 'in_progress', 'pro'],
      ['in_progress', 'completed', 'pro'],
    ];
    for (const [from, to, role] of path) {
      expect(canTransition(from, to, role)).toBe(true);
    }
  });
});
