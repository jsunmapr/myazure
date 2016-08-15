/* Query to list the number of reviews by business category */
/* with a customer rating higher than 3 */
/* */
select
  b.category as business_category,
  count(r.business_id) as number_reviews
from
  wasbmaprpublic.reviews.`business.json` b,
  wasbmaprpublic.reviews.`review.json` r
where
  b.business_id = r.business_id
  and b.location.state = 'CA'
  and cast(b.rating as INT) > 3
group by b.category
order by count(r.business_id) DESC
;
