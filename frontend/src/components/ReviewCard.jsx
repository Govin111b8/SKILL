import StarRating from './StarRating';
import './ReviewCard.css';

function ReviewCard({ review }) {
  const { author, rating, comment, date, avatar } = review;

  return (
    <div className="review-card">
      <div className="review-card-header">
        <img
          src={avatar || `https://ui-avatars.com/api/?name=${encodeURIComponent(author || 'User')}&size=40`}
          alt={author}
          className="review-card-avatar"
        />
        <div className="review-card-meta">
          <h4 className="review-card-author">{author || 'Anonymous'}</h4>
          <span className="review-card-date">
            {date ? new Date(date).toLocaleDateString() : ''}
          </span>
        </div>
        <div className="review-card-stars">
          <StarRating rating={rating} readonly size={14} />
        </div>
      </div>
      <p className="review-card-comment">{comment}</p>
    </div>
  );
}

export default ReviewCard;
