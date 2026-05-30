const logger = require('../config/logger');
const { withRetry } = require('../utils/retry');

let client = null;

function isEnabled() {
  return process.env.MEILI_ENABLED === 'true' && !!process.env.MEILI_HOST && !!process.env.MEILI_MASTER_KEY;
}

async function getClient() {
  if (!isEnabled()) return null;
  if (client) return client;

  try {
    const { MeiliSearch } = require('meilisearch');
    client = new MeiliSearch({
      host: process.env.MEILI_HOST,
      apiKey: process.env.MEILI_MASTER_KEY,
    });
    return client;
  } catch (err) {
    logger.warn({ err: err.message }, 'Meilisearch client unavailable; falling back to SQL search');
    return null;
  }
}

async function searchIndex(indexUid, q, filterString, limit, offset) {
  const meili = await getClient();
  if (!meili) return null;

  try {
    return await withRetry(async () => {
      const response = await meili.index(indexUid).search(q, {
        filter: filterString || undefined,
        limit,
        offset,
      });

      return {
        hits: Array.isArray(response?.hits) ? response.hits : [],
        total: response?.estimatedTotalHits ?? response?.nbHits ?? response?.totalHits ?? 0,
      };
    }, {
      maxRetries: 2,
      baseDelay: 500,
      serviceName: `meilisearch:${indexUid}`,
      shouldRetry: () => true,
    });
  } catch (err) {
    logger.warn({ err: err.message, indexUid }, 'Meilisearch query failed; falling back to SQL search');
    return null;
  }
}

async function searchProfessionals(q, filterString, limit = 20, offset = 0) {
  return searchIndex(process.env.MEILI_PROFESSIONALS_INDEX || 'professionals', q, filterString, limit, offset);
}

async function searchServices(q, filterString, limit = 10, offset = 0) {
  return searchIndex(process.env.MEILI_SERVICES_INDEX || 'services', q, filterString, limit, offset);
}

module.exports = {
  isEnabled,
  searchProfessionals,
  searchServices,
};
