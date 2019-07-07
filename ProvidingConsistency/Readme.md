## Problem

Application necessary to process many requests per second by complicated logic using data from 7 different
tables. We must be able to do CRUD actions for all of that.    

My decision was:   
1. Store data in postgres;
2. Use phoenix scaffolding for fast building admin page with CURD actions for all 7 tables;
3. Cache all necessary data in Mnesia tables. Use them during processing requests.

The problem I solved is "Providing consistency between cache and database".

## Solution

The solution is:
1. Include observer into all necessary ecto models;
2. Implement common interface for all models;
3. Run callback for sending data to Mnesia tables on each CRUD action;
4. Implement handler for all Mnesia tables those receive data and write or delete it from appropriate table.
Also handler could necessary preprocess any data before writing to database. For example create complex 
indexes to increase search speed.

In this folder you can see two folders: "admin" and "sever".      
Inside "admin" there are examples of model and observer implementations.        
Inside "server" there is example handler for mnesia tables.
   
There is left only necessary code to clarify the system of the solution. Comments explain some details.
