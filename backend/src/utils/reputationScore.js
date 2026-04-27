/**
 * Calculate reputation score for a professional.
 * Score is out of 5.0
 *
 * Weights:
 * - average_rating: 0.4
 * - completed_jobs: 0.2
 * - response_time: 0.2
 * - complaints_against: -0.2 (negative factor)
 */
const calculateReputationScore = ({
  averageRating = 0,
  completedJobs = 0,
  responseTime = 0,
  complaintsAgainst = 0,
}) => {
  // Normalize average rating (already out of 5)
  const ratingScore = Math.min(averageRating, 5);

  // Normalize completed jobs (cap at 100 for max score of 5)
  const jobsScore = Math.min((completedJobs / 100) * 5, 5);

  // Response time score: lower is better (in hours, cap at 48)
  // 0 hours = 5, 48+ hours = 0
  const responseScore = Math.max(5 - (responseTime / 48) * 5, 0);

  // Complaints penalty: each complaint reduces score
  const complaintPenalty = Math.min(complaintsAgainst * 1.0, 5);

  const score =
    ratingScore * 0.4 +
    jobsScore * 0.2 +
    responseScore * 0.2 -
    complaintPenalty * 0.2;

  // Clamp between 0 and 5
  return Math.round(Math.max(0, Math.min(5, score)) * 100) / 100;
};

module.exports = { calculateReputationScore };
