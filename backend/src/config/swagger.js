/**
 * OpenAPI 3.0 / Swagger Configuration
 * 
 * Auto-generates API documentation from JSDoc comments in route files.
 * Accessible at /api/docs in development and staging environments.
 */

const swaggerJSDoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const { config } = require('./index');

const swaggerDefinition = {
  openapi: '3.0.3',
  info: {
    title: 'SkillConnect API',
    version: '1.0.0',
    description: `
SkillConnect is a hyperlocal services marketplace connecting customers with skilled professionals.

## Authentication
Most endpoints require a ****** in the Authorization header:
\`\`\`
Authorization: ******
\`\`\`

Access tokens expire after 15 minutes. Use the \`/api/auth/refresh\` endpoint to get a new one.

## Rate Limiting
- Auth endpoints: 30 requests per 15 minutes
- General API: 200 requests per minute
- Search/AI: Per-user limits (30/min search, 10/min AI)
- Payments: 10 requests per minute
- Uploads: 50 per hour

## Error Responses
All errors follow a consistent format:
\`\`\`json
{
  "success": false,
  "message": "Human-readable error description"
}
\`\`\`
    `,
    contact: {
      name: 'SkillConnect API Support',
      email: 'api-support@skillconnect.in',
    },
    license: {
      name: 'Proprietary',
    },
  },
  servers: [
    {
      url: '/api',
      description: 'Current environment',
    },
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Access token from /auth/login or /auth/refresh',
      },
    },
    schemas: {
      Error: {
        type: 'object',
        properties: {
          success: { type: 'boolean', example: false },
          message: { type: 'string', example: 'Error description' },
        },
      },
      Pagination: {
        type: 'object',
        properties: {
          page: { type: 'integer', example: 1 },
          limit: { type: 'integer', example: 20 },
          total: { type: 'integer', example: 100 },
          totalPages: { type: 'integer', example: 5 },
        },
      },
      User: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          name: { type: 'string', example: 'Rajesh Kumar' },
          email: { type: 'string', format: 'email' },
          phone: { type: 'string', example: '+919876543210' },
          role: { type: 'string', enum: ['customer', 'professional', 'agent', 'admin'] },
          location: { type: 'string', example: 'Mumbai, Maharashtra' },
          created_at: { type: 'string', format: 'date-time' },
        },
      },
      Booking: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          customer_id: { type: 'string', format: 'uuid' },
          professional_id: { type: 'string', format: 'uuid' },
          service_id: { type: 'string', format: 'uuid' },
          status: { type: 'string', enum: ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'rejected'] },
          scheduled_date: { type: 'string', format: 'date' },
          scheduled_time: { type: 'string', example: '14:00' },
          amount: { type: 'number', example: 1500.00 },
          notes: { type: 'string' },
          created_at: { type: 'string', format: 'date-time' },
        },
      },
      Professional: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          user_id: { type: 'string', format: 'uuid' },
          category_id: { type: 'string', format: 'uuid' },
          experience_years: { type: 'integer', example: 5 },
          hourly_rate: { type: 'number', example: 500.00 },
          rating: { type: 'number', example: 4.7 },
          total_reviews: { type: 'integer', example: 124 },
          verified: { type: 'boolean' },
          bio: { type: 'string' },
        },
      },
      Category: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          name: { type: 'string', example: 'Plumbing' },
          slug: { type: 'string', example: 'plumbing' },
          icon: { type: 'string' },
          description: { type: 'string' },
          parent_id: { type: 'string', format: 'uuid', nullable: true },
        },
      },
      Review: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          booking_id: { type: 'string', format: 'uuid' },
          reviewer_id: { type: 'string', format: 'uuid' },
          professional_id: { type: 'string', format: 'uuid' },
          rating: { type: 'integer', minimum: 1, maximum: 5 },
          comment: { type: 'string' },
          created_at: { type: 'string', format: 'date-time' },
        },
      },
      Payment: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          booking_id: { type: 'string', format: 'uuid' },
          amount: { type: 'number', example: 1500.00 },
          currency: { type: 'string', example: 'INR' },
          status: { type: 'string', enum: ['pending', 'completed', 'failed', 'refunded', 'cod_pending'] },
          method: { type: 'string', enum: ['razorpay', 'cod', 'wallet', 'emi'] },
          razorpay_order_id: { type: 'string' },
          created_at: { type: 'string', format: 'date-time' },
        },
      },
    },
  },
  security: [{ bearerAuth: [] }],
  tags: [
    { name: 'Auth', description: 'Authentication & authorization' },
    { name: 'Users', description: 'User profile management' },
    { name: 'Professionals', description: 'Professional profiles & discovery' },
    { name: 'Categories', description: 'Service categories' },
    { name: 'Search', description: 'Search & discovery' },
    { name: 'Bookings', description: 'Booking management' },
    { name: 'Payments', description: 'Payment processing' },
    { name: 'Reviews', description: 'Ratings & reviews' },
    { name: 'Messages', description: 'Chat & messaging' },
    { name: 'Notifications', description: 'Push & in-app notifications' },
    { name: 'KYC', description: 'Identity verification' },
    { name: 'Admin', description: 'Admin panel operations' },
    { name: 'Analytics', description: 'Analytics & insights' },
    { name: 'Subscriptions', description: 'Subscription management' },
    { name: 'Upload', description: 'File uploads' },
  ],
};

const options = {
  swaggerDefinition,
  apis: ['./src/routes/*.js'],
};

const swaggerSpec = swaggerJSDoc(options);

/**
 * Mount Swagger UI on the Express app.
 * Only available in development and staging.
 */
function setupSwagger(app) {
  if (config.isProduction) {
    return; // Don't expose docs in production
  }

  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
    customCss: '.swagger-ui .topbar { display: none }',
    customSiteTitle: 'SkillConnect API Docs',
    swaggerOptions: {
      persistAuthorization: true,
      displayRequestDuration: true,
      docExpansion: 'none',
      filter: true,
    },
  }));

  // Raw JSON spec endpoint
  app.get('/api/docs/spec.json', (req, res) => {
    res.json(swaggerSpec);
  });
}

module.exports = { setupSwagger, swaggerSpec };
