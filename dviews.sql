/* Create sample Drill views based on the tables */
/* */
/* Business */
create or replace view dfs.tmp.wasb_bus_vw as
select cast(b.business_id as bigint) as business_id, 
  b.name, 
  b.category, 
  b.rating, 
  b.num_of_reviews, 
  b.attributes.`good for`.dessert as good_for_dessert, 
  b.attributes.`good for`.kids as good_for_kids, 
  b.attributes.`good for`.drinks as good_for_drinks, 
  b.attributes.`good for`.breakfast as good_for_breakfast, 
  b.attributes.`good for`.lunch as good_for_lunch, 
  b.attributes.`good for`.dinner as good_for_dinner, 
  b.attributes.parking.lot as parking_lot, 
  b.attributes.parking.valet as parking_valet, 
  b.attributes.parking.garage as parking_garage, 
  b.attributes.`take reservations` as reservations, 
  b.attributes.`noise level` as noise_level, 
  b.location.city as city, 
  b.location.state as state 
from wasbmaprpublic.reviews.`business.json` b;
/* */
/* Reviews */
create or replace view dfs.tmp.wasb_review_vw as 
select cast(r.business_id as bigint) as business_id, 
  cast(r.user_id as bigint) as user_id, 
  r.rating, 
  r.`date`, 
  r.review_text, 
  r.votes.helpful as helpful_votes, 
  r.votes.cool as cool_votes, 
  r.votes.unhelpful as unhelpful_votes 
from wasbmaprpublic.reviews.`review.json` r;
/* */
/* User */
create or replace view dfs.tmp.wasb_user_vw as 
select cast(u.user_id as bigint) as user_id, 
  u.name, 
  u.gender, 
  u.age, 
  u.review_count, 
  u.avg_rating, 
  u.user_votes.helpful as helpful_votes, 
  u.user_votes.cool as cool_votes, 
  u.user_votes.unhelpful as unhelpful_votes, 
  u.friends_count 
from wasbmaprpublic.reviews.`user.json` u;
