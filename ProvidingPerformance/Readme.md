## Problem

Application is necessary to find most appropriate subnet by IP address of the client.
Also it must process several thousands requests per second. 
The logic is:

1. There are approximately 1000 records in the database those contains Subnets data. IP address range by using CIDR;
2. When client makes request you must get it's IP and find all Subnets those IP addresses range include that IP;
3. Find the most specific(Those CIDR mask is largest).

I implemented first solution by using https://github.com/c-rack/cidr-elixir. Wrote unit tests.
It takes completely correct answers but after measurement i find out that one search is takes from 5 to 10 ms.
And load testing shows that application processes only 200 requests per second. It's completely unacceptable.
So how to save correct answers and increase performance?

## Solution

The problem was in algorithm of course. It's complexity was linear N(0). Data records was inside Mnesia table 
but still sequence search is very slow. We must check all records for each request.

The solution was to change CIDR store format and use mnesia index for searching to provide Log(O) algorithm complexity.

I thing it's rather good example of using data structures and algorithms in solving technical problems.

There are two folders with code examples `before_optimisation` and `after_optimisation`. All extra code those does not 
related to topic has been removed.
