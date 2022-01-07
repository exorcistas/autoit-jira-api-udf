# JIRA REST API

## Table of Contents
+ [About](#about)
+ [Prerequisites](#prerequisites)
+ [Installation](#installation)
+ [Usage](#usage)
+ [Documentation](#documentation)


## About <a name = "about"></a>
This UDF is an AutoIt wrapper for 'JIRA REST API'.   
It uses web requests to communicate to JIRA platform and perform certain project based actions.  
```Note, that not all functionality might be mapped or updated in current published version.```

## Prerequisites <a name = "prerequisites"></a>
User must be authorized and have access to JIRA project

## Installation <a name = "installation"></a>
* Simply copy ```.au3``` files to your development directory and use ```#include``` to point to these files in the source code. 
* Set variables in Core UDF for environment specific needs. 
* UDF requires ```Json.au3``` as a dependency, which is included.

## Usage <a name = "usage"></a>
Use ```JIRA_REST_API_Core.au3``` for core functionality to JIRA.   
Consider creating project-specific JIRA UDF for your needs, since each project has unique setup.

## Documentation <a name = "documentation"></a>
* [JIRA REST API Documentation](https://docs.atlassian.com/software/jira/docs/api/REST)