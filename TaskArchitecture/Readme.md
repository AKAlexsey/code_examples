## Problem

It's necessary to expose XML with for given specification. XML feed contains job offers that must be fetched from some API. Required XML data structure is different from job offers source so it's necessary to complement with manual fields. After complement result job entities validated and than compiled to XML files.  

This process must run asynchronously. If there will be any type of error expected or unexpected - necessary to log it.

So I separate process into 7 steps. 

1. Getting and validating Export Companies
2. Fetching offices for companies
3. Fetching job offers for companies
4. Filtering job offers by limitations (not implemented yet)
5. Validating job offers
6. Converting job offers to files
7. Saving XML files to store

I used **Railway** and **Chain of responsibility** patterns.   
  
**Railway pattern**      
Process run in Task. It's logic in `TaskArchitecture.Services.Export.ExportWorker` file in `#run` function. If unexpected error gonna happen it will be rescued and error with stacktrace will be written as fail result.  

**Chain of responsibility pattern**    
Data between all steps transfers wih `TaskArchitecture.Model.ExportReport` data structure.
All success results put into appropriate step. All errors put into `failed_reasons` and failed results (for debug purposes. For example if some job offers failed validations, process continues but failed job offers puts into failed results).   

## DDD example    
This code is example of one domain. Other domain does not have common modules except utils and helper functions like Format exceptions. I just copied code here, and renamed some modules to anonymize the project.



