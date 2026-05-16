/**
 * Job queue service for handling background tasks and traffic spikes.
 * Uses in-memory queue with configurable concurrency.
 * 
 * Handles:
 * - Notification dispatch (batch processing)
 * - Analytics event processing
 * - Email/SMS sending
 * - Emergency broadcast notifications
 * - Search indexing updates
 * 
 * For production at scale:
 * - Replace with Bull/BullMQ + Redis for multi-instance support
 * - Current implementation handles single-instance up to ~5K concurrent
 */

const logger = require('../config/logger');

class JobQueue {
  constructor(name, options = {}) {
    this.name = name;
    this.concurrency = options.concurrency || 3;
    this.maxRetries = options.maxRetries || 3;
    this.retryDelay = options.retryDelay || 1000; // ms
    this.queue = [];
    this.running = 0;
    this.processed = 0;
    this.failed = 0;
    this.handlers = new Map();
    this.paused = false;
  }

  /**
   * Register a job handler
   */
  process(jobType, handler) {
    this.handlers.set(jobType, handler);
    return this;
  }

  /**
   * Add a job to the queue
   */
  add(jobType, data, options = {}) {
    const job = {
      id: `${this.name}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      type: jobType,
      data,
      attempts: 0,
      maxAttempts: options.maxRetries || this.maxRetries,
      priority: options.priority || 0,
      delay: options.delay || 0,
      createdAt: Date.now(),
      status: 'waiting',
    };

    // Insert based on priority (higher priority first)
    if (job.priority > 0) {
      const insertIdx = this.queue.findIndex(j => j.priority < job.priority);
      if (insertIdx === -1) {
        this.queue.push(job);
      } else {
        this.queue.splice(insertIdx, 0, job);
      }
    } else {
      this.queue.push(job);
    }

    // Process queue
    if (!this.paused) this._processNext();

    return job.id;
  }

  /**
   * Add multiple jobs at once (batch)
   */
  addBulk(jobType, dataArray, options = {}) {
    return dataArray.map(data => this.add(jobType, data, options));
  }

  /**
   * Process next job in queue
   */
  async _processNext() {
    if (this.paused || this.running >= this.concurrency || this.queue.length === 0) return;

    const job = this.queue.shift();
    if (!job) return;

    // Handle delayed jobs
    if (job.delay > 0 && (Date.now() - job.createdAt) < job.delay) {
      setTimeout(() => {
        this.queue.unshift(job);
        this._processNext();
      }, job.delay - (Date.now() - job.createdAt));
      return;
    }

    const handler = this.handlers.get(job.type);
    if (!handler) {
      logger.warn(`No handler for job type: ${job.type} in queue: ${this.name}`);
      this.failed++;
      this._processNext();
      return;
    }

    this.running++;
    job.status = 'active';
    job.attempts++;

    try {
      await handler(job.data, job);
      job.status = 'completed';
      this.processed++;
    } catch (error) {
      logger.error(`Job ${job.id} failed (attempt ${job.attempts}/${job.maxAttempts}):`, error.message);

      if (job.attempts < job.maxAttempts) {
        job.status = 'waiting';
        // Exponential backoff
        job.delay = this.retryDelay * Math.pow(2, job.attempts - 1);
        job.createdAt = Date.now();
        this.queue.push(job);
      } else {
        job.status = 'failed';
        this.failed++;
        logger.error(`Job ${job.id} permanently failed after ${job.maxAttempts} attempts`);
      }
    } finally {
      this.running--;
      this._processNext();
    }
  }

  /**
   * Pause processing
   */
  pause() {
    this.paused = true;
  }

  /**
   * Resume processing
   */
  resume() {
    this.paused = false;
    // Process pending jobs
    for (let i = 0; i < this.concurrency; i++) {
      this._processNext();
    }
  }

  /**
   * Get queue stats
   */
  stats() {
    return {
      name: this.name,
      waiting: this.queue.length,
      running: this.running,
      processed: this.processed,
      failed: this.failed,
      paused: this.paused,
    };
  }

  /**
   * Drain queue — wait for all jobs to complete
   */
  async drain() {
    return new Promise((resolve) => {
      const check = () => {
        if (this.queue.length === 0 && this.running === 0) {
          resolve();
        } else {
          setTimeout(check, 100);
        }
      };
      check();
    });
  }
}

// ====== Queue Instances ======

// Notification dispatch queue (high throughput)
const notificationQueue = new JobQueue('notifications', { concurrency: 5, maxRetries: 3 });

// Analytics processing queue (background, non-critical)
const analyticsQueue = new JobQueue('analytics', { concurrency: 2, maxRetries: 2 });

// Communication queue (email, SMS)
const commsQueue = new JobQueue('communications', { concurrency: 3, maxRetries: 3 });

// Emergency broadcast queue (high priority, fast)
const emergencyQueue = new JobQueue('emergency', { concurrency: 10, maxRetries: 1 });

// ====== Register Default Handlers ======

notificationQueue.process('push', async (data) => {
  const { sendPush } = require('../services/pushNotification');
  if (sendPush) await sendPush(data.userId, data.title, data.body, data.data);
});

notificationQueue.process('in_app', async (data) => {
  const { query } = require('../config/database');
  await query(
    `INSERT INTO notifications (user_id, type, title, body, related_id) VALUES ($1, $2, $3, $4, $5)`,
    [data.userId, data.type || 'system', data.title, data.body, data.relatedId || null]
  );
});

commsQueue.process('email', async (data) => {
  const emailService = require('../services/email');
  await emailService.sendEmail(data);
});

commsQueue.process('sms', async (data) => {
  const smsService = require('../services/sms');
  await smsService.sendSMS(data.to || data.phone, data.message || data.text);
});

emergencyQueue.process('broadcast', async (data) => {
  const { query } = require('../config/database');
  // Send notification to all target professionals
  for (const proUserId of data.targetUserIds) {
    await query(
      `INSERT INTO notifications (user_id, type, title, body, related_id) VALUES ($1, 'system', $2, $3, $4)`,
      [proUserId, data.title, data.body, data.relatedId]
    );
  }
});

// ====== Exports ======

function getQueueStats() {
  return {
    notifications: notificationQueue.stats(),
    analytics: analyticsQueue.stats(),
    communications: commsQueue.stats(),
    emergency: emergencyQueue.stats(),
  };
}

module.exports = {
  JobQueue,
  notificationQueue,
  analyticsQueue,
  commsQueue,
  emergencyQueue,
  getQueueStats,
};
