#Exercise 1:
#Marketing manger would like to rename gift baskets emphasizing products \value",
#therefore he would like a report. [Tip: apply the strategy to find maximum
 #and minimum separately]
(SELECT B.basket_name, MAX(F.price) AS price, 'MAX' AS value
FROM food F JOIN basketCombines B
ON (F.name = B.food_name
AND F.unit = B.food_unit
AND F.weight = B.food_weight)
GROUP BY B.basket_name)
UNION
(SELECT B.basket_name, MIN(F.price) AS price, 'MIN' AS value
FROM food F JOIN basketCombines B
ON (F.name = B.food_name
AND F.unit = B.food_unit
AND F.weight = B.food_weight)
GROUP BY B.basket_name)
ORDER BY basket_name, price;

#Exercise 2: Are there available [currently: endDate IS NULL] at least two distinct products (at
#least in name and price) of the same manufacturer for the same menu? [Tip: identify
#manufacturer by means of food.label]

SELECT DISTINCT F1.label, F1.menu_name
FROM food F1, food F2
WHERE F1.label = F2.label
AND F1.menu_name = F2.menu_name
AND F1.price > F2.price
AND F1.name <> F2.name
AND (F1.endDate IS NULL AND F2.endDate IS NULL);

#Exercise 3: It could be helpful to analyze food product selections in specfic time intervals. Are
#there days [= date] six months ago, such date users selected at least 3 products? [Tip:
#consider the process to count number of selections six months ago]

SELECT date, COUNT(User.ID) AS nr
FROM User JOIN selected ON User.ID = selected.ID
WHERE month(date) = month(now()) - 6
GROUP BY date
HAVING nr > 3;